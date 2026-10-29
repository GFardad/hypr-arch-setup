export type SearchField = "name" | "keywords" | "entry" | "executable" | "description"

export interface Searchable<T> {
	app: T
	name: string
	keywords?: string[]
	entry?: string
	executable?: string
	description?: string
}

/** Relative weight of a match in each field. Name dominates, entry/executable keep such
 * apps findable even when their display name does not contain the query. */
const FIELD_WEIGHT: Record<SearchField, number> = {
	name: 1,
	executable: 0.9, // e.g. "nwg-displays"
	entry: 0.8, // e.g. "nwg-displays.desktop"
	keywords: 0.6,
	description: 0.35,
}

function field_score(text: string | undefined, normalized: string, weight: number): number {
	if (!text) return 0
	const index = text.toLowerCase().indexOf(normalized)
	if (index < 0) return 0
	// earlier matches score higher; scale by field weight
	return weight * (1 - index / (text.length + 1))
}

export function rank_apps<T>(index: Array<Searchable<T>>, query: string, limit: number): T[] {
	const normalized = query.trim().toLowerCase()
	if (!normalized || !Number.isFinite(limit) || limit < 0) return []
	const count = limit === 0 ? 9 : Math.floor(limit)
	return index
		.map((item) => {
			const scores = [
				field_score(item.name, normalized, FIELD_WEIGHT.name),
				field_score(item.executable, normalized, FIELD_WEIGHT.executable),
				field_score(item.entry, normalized, FIELD_WEIGHT.entry),
				field_score(item.keywords?.join(" "), normalized, FIELD_WEIGHT.keywords),
				field_score(item.description, normalized, FIELD_WEIGHT.description),
			]
			return { item, score: Math.max(...scores) }
		})
		.filter((item) => item.score > 0)
		.sort((left, right) => right.score - left.score || left.item.name.localeCompare(right.item.name))
		.slice(0, count)
		.map((item) => item.item.app)
}

export function display_apps<T>(apps: T[], bottom: boolean) {
	const ordered = bottom ? [...apps].reverse() : apps
	return ordered.map((app, rank) => ({ app, rank }))
}
