import start_shell from "$shell/startup"
import env from "$lib/env"

import app from "$lib/app"
import { createRoot } from "ags"
import { Gdk } from "ags/gtk4"
import { idle, timeout, Timer } from "$lib/time"

import { PowerMenu } from "widget/PowerMenu"
import { Launcher } from "widget/Bar/components/Launcher"
import { Notifications } from "widget/Bar/components/Notifications"
import { QuickSettings } from "widget/Bar/components/QuickSettings"
import { DateMenu } from "widget/Bar/components/DateMenu"
import { OSD } from "widget/OSD"
import { Overview } from "widget/Bar/components/Overview"
import { Bar } from "widget/Bar"
import { Dock } from "widget/Dock"
import { Desktop } from "widget/Desktop"

import { hyprland } from "$lib/hyprland"
import { screen_capture } from "$service/screenCapture"
import { flush_options } from "$shell/options"
import { log_error } from "$lib/result"

const deferred_roots: Array<() => void> = []
let stopping = false
let ready = false
let quitting = false
let startup_failed = false

function mount_deferred_windows(build: () => void) {
	deferred_roots.push(
		createRoot((dispose) => {
			build()
			return dispose
		}),
	)
}

async function toggle_recording(scope: "focused" | "area") {
	if (screen_capture.recording || screen_capture.starting) {
		const stopped = screen_capture.stop_recording()
		return stopped.ok ? "accepted" : `Recording failed: ${stopped.err}`
	}
	const started = await screen_capture.start_recording({ scope })
	return started.ok ? started.value : `Recording failed: ${started.err}`
}

app.before_quit = async () => {
	quitting = true
	try {
		const options = await flush_options()
		if (!log_error(options, "shell.quit: Failed to flush options") && !startup_failed)
			return false
		const recording = await screen_capture.shutdown()
		log_error(recording, "shell.quit: Failed to stop recorder")
		stopping = true
		return true
	} finally {
		if (!stopping) quitting = false
	}
}

app.start({
	instanceName: env.appName,
	async main() {
		const started = await start_shell()
		if (!log_error(started, "shell.startup: Failed to initialize")) {
			startup_failed = true
			app.quit()
			return
		}
		const active_monitor_windows = new Map<
			string,
			{ monitor: Gdk.Monitor; dispose: Array<() => void> }
		>()
		let monitor_windows_stopped = false
		const sync_monitor_windows = () => {
			const live_connectors = new Set(
				hyprland.monitors.map((monitor) => monitor.name),
			)
			const current = new Map(
				app
					.get_monitors()
					.filter((monitor) => {
						const connector = monitor.get_connector()
						return connector == null || live_connectors.has(connector)
					})
					.map((monitor) => {
						const geometry = monitor.get_geometry()
						const key = monitor.get_connector() ?? `mon-${geometry.x}x${geometry.y}`
						return [key, monitor] as const
					}),
			)

			for (const [key, windows] of active_monitor_windows) {
				if (current.get(key) !== windows.monitor) {
					windows.dispose.forEach((dispose) => dispose())
					active_monitor_windows.delete(key)
				}
			}

			for (const [key, monitor] of current) {
				if (!active_monitor_windows.has(key)) {
					active_monitor_windows.set(key, {
						monitor,
						dispose: [
							createRoot((dispose) => {
								Bar({ gdkmonitor: monitor })
								return dispose
							}),
							createRoot((dispose) => {
								Desktop.Window({ gdkmonitor: monitor })
								return dispose
							}),
							createRoot((dispose) => {
								Dock.Window({ gdkmonitor: monitor })
								return dispose
							}),
							createRoot((dispose) => {
								Desktop.ContextMenuWindow({ gdkmonitor: monitor })
								return dispose
							}),
						],
					})
				}
			}
		}

		const monitor_handler = app.connect("notify::monitors", sync_monitor_windows)
		const hypr_monitor_added_handler = hyprland.connect(
			"monitor-added",
			sync_monitor_windows,
		)
		const hypr_monitor_removed_handler = hyprland.connect(
			"monitor-removed",
			sync_monitor_windows,
		)
		let monitor_shutdown_handler = 0
		const cleanup_monitor_windows = () => {
			if (monitor_windows_stopped) return
			monitor_windows_stopped = true
			app.disconnect(monitor_handler)
			hyprland.disconnect(hypr_monitor_added_handler)
			hyprland.disconnect(hypr_monitor_removed_handler)
			if (monitor_shutdown_handler) app.disconnect(monitor_shutdown_handler)
			for (const windows of active_monitor_windows.values())
				windows.dispose.forEach((dispose) => dispose())
			active_monitor_windows.clear()
		}

		monitor_shutdown_handler = app.connect("shutdown", cleanup_monitor_windows)
		sync_monitor_windows()

		idle(() => {
			idle(() => {
				mount_deferred_windows(() => {
					DateMenu.Window()
					PowerMenu.Window()
					if (!app.get_window("verification")) PowerMenu.VerificationModal()
					Notifications.Window()
					QuickSettings.Window()
					OSD.Window()
				})
				idle(() => {
					mount_deferred_windows(() => {
						Launcher.Window()
						Overview.Window()
					})
				})
			})
		})
		app.connect("shutdown", () => {
			ready = false
			stopping = true
			for (const dispose of deferred_roots.splice(0)) dispose()
		})
		ready = true
	},
	requestHandler(argv: string[], res: (response: string) => void) {
		const [request, ...rest] = argv
		if (!ready || quitting || stopping) {
			res("Shell is starting or stopping")
			return
		}

		switch (request) {
			case "launcher-search": {
				const query = rest.join(" ")
				if (!app.get_window("launcher"))
					mount_deferred_windows(() => Launcher.Window())
				Launcher.set_search_query(query, true)
				break
			}
			case "shutdown":
				if (!app.get_window("verification"))
					mount_deferred_windows(() => PowerMenu.VerificationModal())
				PowerMenu.request_action_confirmation("shutdown")
				break
			case "quit":
				res("accepted")
				timeout(100, () => app.quit())
				return
			case "record":
				void toggle_recording("focused").then(res)
				return
			case "record-area":
				void toggle_recording("area").then(res)
				return
			case "screenshot":
				void screen_capture.screenshot({ scope: "focused" }).then((result) =>
					res(result.ok ? result.value : `Screenshot failed: ${result.err}`),
				)
				return
			case "screenshot-area":
				void screen_capture.screenshot({ scope: "area" }).then((result) =>
					res(result.ok ? result.value : `Screenshot failed: ${result.err}`),
				)
				return
			default:
				res(`Unknown request: ${request}`)
				return
		}

		res("accepted")
	},
})
