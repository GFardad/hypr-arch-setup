import { test } from "node:test"
import assert from "node:assert/strict"
import { rank_apps, display_apps } from "../../widget/Bar/components/Launcher/search.ts"

test("query changes reorder existing results and preserve distinct desktop entries", () => {
	const index = [
		{ app: { id: "native.desktop" }, name: "ab" },
		{ app: { id: "flatpak.desktop" }, name: "ba" },
		{ app: { id: "second-native.desktop" }, name: "ab" },
	]
	assert.deepEqual(rank_apps(index, "a", 9).map((app) => app.id), [
		"native.desktop", "second-native.desktop", "flatpak.desktop",
	])
	assert.deepEqual(rank_apps(index, "b", 9).map((app) => app.id), [
		"flatpak.desktop", "native.desktop", "second-native.desktop",
	])
})

test("apps are findable by entry and executable when the display name hides them", () => {
	const index = [
		{
			app: "nwg-displays.desktop",
			name: "Displays Settings",
			entry: "nwg-displays.desktop",
			executable: "nwg-displays",
		},
		{
			app: "nwg-look.desktop",
			name: "GTK Settings",
			entry: "nwg-look.desktop",
			executable: "nwg-look",
		},
		{
			app: "firefox.desktop",
			name: "Firefox",
			entry: "firefox.desktop",
			executable: "firefox",
			keywords: ["browser", "web", "internet"],
		},
	]
	assert.deepEqual(rank_apps(index, "nwg", 9), ["nwg-displays.desktop", "nwg-look.desktop"])
	assert.deepEqual(rank_apps(index, "nwg-display", 9), ["nwg-displays.desktop"])
	assert.deepEqual(rank_apps(index, "NWG", 9), ["nwg-displays.desktop", "nwg-look.desktop"])
})

test("a display-name match outranks an entry or executable match", () => {
	const index = [
		{ app: "entry", name: "Something Else", entry: "settings.desktop", executable: "settings" },
		{ app: "name", name: "Settings", entry: "control.desktop", executable: "control" },
	]
	assert.deepEqual(rank_apps(index, "settings", 9), ["name", "entry"])
})

test("keywords and descriptions are searchable below the name", () => {
	const index = [
		{ app: "firefox.desktop", name: "Firefox", keywords: ["browser", "web"], description: "Browse the web" },
		{ app: "notes.desktop", name: "Notes", description: "Take a note in the browser" },
	]
	assert.deepEqual(rank_apps(index, "browser", 9), ["firefox.desktop", "notes.desktop"])
})

test("bottom display numbering matches shortcut order", () => {
	const results = rank_apps([
		{ app: "ab", name: "ab" },
		{ app: "ba", name: "ba" },
	], "a", 9)
	assert.deepEqual(display_apps(results, false), [
		{ app: "ab", rank: 0 }, { app: "ba", rank: 1 },
	])
	assert.deepEqual(display_apps(results, true), [
		{ app: "ba", rank: 0 }, { app: "ab", rank: 1 },
	])
})

test("zero preserves the legacy nine-result fallback and explicit counts are honored", () => {
	const index = [
		{ app: "one", name: "app one" },
		{ app: "two", name: "app two" },
	]
	assert.deepEqual(rank_apps(index, "app", 0), ["one", "two"])
	assert.deepEqual(rank_apps(index, "app", 1), ["one"])
	assert.deepEqual(rank_apps(index, "  ", 9), [])
	assert.deepEqual(rank_apps(index, "nothing matches this", 9), [])
	const catalog = Array.from({ length: 20 }, (_, index) => ({ app: index, name: `app ${String(index).padStart(2, "0")}` }))
	assert.equal(rank_apps(catalog, "app", 0).length, 9)
	assert.equal(rank_apps(catalog, "app", 15).length, 15)
	assert.equal(rank_apps(catalog, "app", 100).length, catalog.length)
	assert.deepEqual(rank_apps(catalog, "app", -1), [])
	assert.deepEqual(rank_apps(catalog, "app", Number.POSITIVE_INFINITY), [])
})
