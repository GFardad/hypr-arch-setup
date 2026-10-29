import app from "$lib/app"
import { Astal, Gtk } from "ags/gtk4"
import { type Timer, timeout } from "$lib/time"
import { createState, onCleanup } from "ags"

import AstalWp from "gi://AstalWp"

import { PopupWindow, Position } from "widget/shared/PopupWindow"

import { brightness } from "$service/brightness"
import { get_brightness_icon } from "$lib/icons"
import { ignore_input } from "$lib/windowing"
import options, { Opt } from "$shell/options"

const audio = AstalWp.get_default()

export namespace OSD {
	export function Window() {
		if (window) return window
		const disconnect_listeners = connect_listeners()
		onCleanup(() => {
			hide_timer?.cancel()
			hide_timer = undefined
			disconnect_listeners()
			window = null
		})
		window = (
			<PopupWindow
				name="state-display"
				visible={reveal}
				keymode={NONE}
				exclusivity={IGNORE}
				anchor={undefined}
				layer={OVERLAY}
				application={app}
				layout={options.osd.position as Opt<Position>}
				handleClosing={false}
				onNotifyVisible={ignore_input}
				$={ignore_input}
			>
				<Gtk.AspectFrame obeyChild={false} ratio={1}>
					<box class="state-display" orientation={VERTICAL} hexpand vexpand>
						<image
							iconName={content.as((value) => value.icon)}
							pixelSize={options.scale.as((scale) =>
								Math.round((64 * scale) / 100),
							)}
							useFallback
							vexpand
							hexpand
						/>
						<Gtk.ProgressBar
							class={content.as((value) =>
								value.muted ? "percentage muted" : "percentage",
							)}
							fraction={content.as((value) => Number.isFinite(value.value) ? Math.max(0, Math.min(1, value.value)) : 0)}
							hexpand
						/>
					</box>
				</Gtk.AspectFrame>
			</PopupWindow>
		) as Gtk.Window
		return window
	}

	type osd_content = {
		icon: string
		value: number
		muted: boolean
	}

	const [reveal, set_reveal] = createState(false)
	const [content, set_content] = createState<osd_content>({
		icon: "",
		value: 0,
		muted: false,
	})

	let hide_timer: Timer | undefined
	let window: Gtk.Window | null = null

	function show(value: number, icon: string, muted: boolean) {
		set_content({ value, icon, muted })
		set_reveal(true)

		hide_timer?.cancel()
		hide_timer = timeout(options.osd.dismiss.peek(), () => {
			set_reveal(false)
		})
	}

	function connect_listeners() {
		type audio_endpoint = ReturnType<typeof audio.get_default_speaker>

		const watch_endpoint = (
			get_endpoint: () => audio_endpoint,
			default_changed_signal: string,
			quiet_corrections = false,
		) => {
			let endpoint: audio_endpoint | null = null
			let endpoint_handlers: number[] = []

			// An automatic gain-control style correction shows up as a small
			// volume drop followed almost immediately by a restore to the
			// previous level. Those are not user actions, so the OSD stays quiet
			// for them; otherwise every correction pops the overlay twice. A
			// genuine volume key/scroll changes the level and does not snap
			// straight back, so it still shows. Only the microphone needs this:
			// its level is pinned by an external latching service, while the
			// speaker is adjusted by hand.
			const CORRECTION_WINDOW_MS = 1500
			let last_change_at = 0
			let last_value: number | null = null

			const is_machine_correction = (value: number) => {
				const now = Date.now()
				const prev = last_value
				const is_snap_back =
					prev !== null &&
					value > prev &&
					now - last_change_at < CORRECTION_WINDOW_MS
				last_change_at = now
				last_value = value
				return is_snap_back
			}

			const disconnect_endpoint = () => {
				if (endpoint) {
					for (const handler of endpoint_handlers) endpoint.disconnect(handler)
				}
				endpoint = null
				endpoint_handlers = []
			}

			const reconnect_endpoint = () => {
				disconnect_endpoint()
				endpoint = get_endpoint()
				if (!endpoint) return

				const show_endpoint = () => {
					if (!endpoint) return
					const value = endpoint.get_volume()
					if (quiet_corrections && is_machine_correction(value)) return
					show(value, endpoint.get_volume_icon(), endpoint.get_mute())
				}
				endpoint_handlers = [
					endpoint.connect("notify::volume", show_endpoint),
					endpoint.connect("notify::mute", show_endpoint),
				]
			}

			reconnect_endpoint()
			const default_handler = audio.connect(
				default_changed_signal,
				reconnect_endpoint,
			)

			return () => {
				audio.disconnect(default_handler)
				disconnect_endpoint()
			}
		}

		const disconnect_speaker = watch_endpoint(
			() => audio.get_default_speaker(),
			"notify::default-speaker",
		)
		const disconnect_microphone = watch_endpoint(
			() => audio.get_default_microphone(),
			"notify::default-microphone",
			true,
		)
		const display_handler = brightness.connect("notify::display", () => {
			if (!brightness.initialized) return
			show(
				brightness.display,
				get_brightness_icon(brightness.display, "screen"),
				false,
			)
		})
		const keyboard_handler = brightness.connect("notify::kbd", () => {
			if (!brightness.initialized) return
			show(brightness.kbd, get_brightness_icon(brightness.kbd, "keyboard"), false)
		})

		return () => {
			disconnect_speaker()
			disconnect_microphone()
			brightness.disconnect(display_handler)
			brightness.disconnect(keyboard_handler)
		}
	}

	const { VERTICAL } = Gtk.Orientation
	const { OVERLAY } = Astal.Layer
	const { IGNORE } = Astal.Exclusivity
	const { NONE } = Astal.Keymode
}
