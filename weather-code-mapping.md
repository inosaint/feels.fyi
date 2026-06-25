# Weather Code Mapping

Reference for mapping Open-Meteo WMO weather codes to illustration states.

## WMO Codes

| Code | Description |
| --- | --- |
| 0 | Clear sky |
| 1, 2, 3 | Mainly clear, partly cloudy, and overcast |
| 45, 48 | Fog and depositing rime fog |
| 51, 53, 55 | Drizzle: light, moderate, and dense intensity |
| 56, 57 | Freezing drizzle: light and dense intensity |
| 61, 63, 65 | Rain: slight, moderate, and heavy intensity |
| 66, 67 | Freezing rain: light and heavy intensity |
| 71, 73, 75 | Snow fall: slight, moderate, and heavy intensity |
| 77 | Snow grains |
| 80, 81, 82 | Rain showers: slight, moderate, and violent |
| 85, 86 | Snow showers: slight and heavy |
| 95 | Thunderstorm: slight or moderate |
| 96, 99 | Thunderstorm with slight and heavy hail |

## Intended Illustration Mapping

| State | Codes / Rule | Illustration idea |
| --- | --- | --- |
| Hot | Temperature > 35 C, except rain/storm/fog | Ice cream cone |
| Clear | 0, 1 | Tiled rooftop with clay cockerel |
| Cloudy | 2, 3 | Rooftop clothesline with gently flowing clothes |
| Fog / Mist | 45, 48; or inferred mist from high humidity, high cloud cover, low wind | Two-wheeler / torch headlight silhouette |
| Drizzle | 51, 53, 55 | Tea glass and fried pakode |
| Rain | 61, 63, 65, 80, 81, 82 | Dirty muddy blue-and-white rubber chappals |
| Windy | High wind when not raining | Umbrella |
| Cold | Temperature < 18 C; freezing drizzle/rain; snow codes | Monkey cap |
| Storm | 95, 96, 99 | Power-cut darkness / storm-specific art |

## Current App Mapping

| State | Current asset |
| --- | --- |
| Hot | `images/hot35.png` |
| Clear morning/day | `images/clear-sky-morning.png` |
| Clear evening | `images/clear-sky-evening.png` |
| Cloudy | `images/cloudy.png` |
| Fog / Mist | `images/fog.png` |
| Rain / Windy fallback | `images/heavy rain and wind.png` |

Unimplemented states currently fall back to the rain/windy asset until their illustrations are added.
