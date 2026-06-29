const DEFAULT_CITY = {
  name: "Bangalore",
  country: "India",
  latitude: 12.9716,
  longitude: 77.5946
};
const DEFAULT_RANKING_COORDS = {
  latitude: DEFAULT_CITY.latitude,
  longitude: DEFAULT_CITY.longitude
};

const weatherGroups = {
  clear: new Set([0, 1]),
  cloudy: new Set([2, 3]),
  fog: new Set([45, 48]),
  drizzle: new Set([51, 53, 55, 56, 57, 61]),
  rain: new Set([63, 65, 66, 67, 80, 81]),
  storm: new Set([82, 95, 96, 99]),
  snow: new Set([71, 73, 75, 77, 85, 86])
};

const labels = new Map([
  [0, "Sunny"],
  [1, "Mostly sunny"],
  [2, "Partly cloudy"],
  [3, "Cloudy"],
  [45, "Foggy"],
  [48, "Foggy"],
  [51, "Drizzle"],
  [53, "Drizzle"],
  [55, "Drizzle"],
  [56, "Icy drizzle"],
  [57, "Icy drizzle"],
  [61, "Light rain"],
  [63, "Rain"],
  [65, "Heavy rain"],
  [66, "Icy rain"],
  [67, "Icy rain"],
  [71, "Light snow"],
  [73, "Snow"],
  [75, "Heavy snow"],
  [77, "Snow grains"],
  [80, "Rain showers"],
  [81, "Rain showers"],
  [82, "Heavy showers"],
  [85, "Snow showers"],
  [86, "Snow showers"],
  [95, "Stormy"],
  [96, "Thunderstorm"],
  [99, "Thunderstorm"]
]);

const temperatureEl = document.querySelector("#temperature");
const conditionEl = document.querySelector("#condition");
const inputEl = document.querySelector("#locationInput");
const searchForm = document.querySelector("#searchForm");
const resultsEl = document.querySelector("#results");
const locationLabelEl = document.querySelector("#locationLabel");
const locationTriggerEl = document.querySelector("#locationTrigger");
const searchOverlayEl = document.querySelector("#searchOverlay");
const overlayCloseEl = document.querySelector("#overlayClose");

let searchController;
let currentCity = DEFAULT_CITY;
let activeResultIndex = -1;
let userCoords;

function getPreferredLocale() {
  return navigator.languages?.find(Boolean) || navigator.language || "en";
}

function getLocaleMeasurementSystem(locale) {
  try {
    const intlLocale = new Intl.Locale(locale);
    if (intlLocale.measurementSystem) {
      return intlLocale.measurementSystem;
    }

    if (typeof intlLocale.getMeasurementSystems === "function") {
      return intlLocale.getMeasurementSystems()[0] || "";
    }
  } catch (error) {
    // Fall through to parsing the locale string.
  }

  const measurementMatch = locale.toLowerCase().match(/-u(?:-[a-z0-9]{2,8})*-ms-([a-z0-9]{3,8})/);
  return measurementMatch?.[1] || "";
}

function getLocaleRegion(locale) {
  try {
    return new Intl.Locale(locale).region || "";
  } catch (error) {
    const regionMatch = locale.match(/^[a-z]{2,3}(?:-[a-z]{4})?-([a-z]{2}|\d{3})(?:-|$)/i);
    return regionMatch?.[1]?.toUpperCase() || "";
  }
}

function shouldDisplayFahrenheit(locale = getPreferredLocale()) {
  const measurementSystem = getLocaleMeasurementSystem(locale);

  if (measurementSystem === "ussystem" || measurementSystem === "us") {
    return true;
  }

  if (measurementSystem === "metric" || measurementSystem === "uksystem") {
    return false;
  }

  return getLocaleRegion(locale) === "US";
}

function formatTemperature(temperatureCelsius, locale) {
  const displayTemperature = shouldDisplayFahrenheit(locale)
    ? temperatureCelsius * 9 / 5 + 32
    : temperatureCelsius;

  return `${Math.round(displayTemperature)}<span class="degree">&deg;</span>`;
}

function setStatus(message) {
  inputEl.dataset.status = message;
}

function setLocation(city) {
  currentCity = city;
  locationLabelEl.textContent = city.country ? `${city.name}, ${city.country}` : city.name;
  inputEl.value = city.name;
}

function getDistanceKm(start, end) {
  const radiusKm = 6371;
  const toRadians = (degrees) => degrees * Math.PI / 180;
  const latDistance = toRadians(end.latitude - start.latitude);
  const lonDistance = toRadians(end.longitude - start.longitude);
  const startLat = toRadians(start.latitude);
  const endLat = toRadians(end.latitude);
  const angle = Math.sin(latDistance / 2) ** 2
    + Math.cos(startLat) * Math.cos(endLat) * Math.sin(lonDistance / 2) ** 2;

  return radiusKm * 2 * Math.atan2(Math.sqrt(angle), Math.sqrt(1 - angle));
}

function getPopularityScore(result, query) {
  const normalizedQuery = query.trim().toLowerCase();
  const normalizedName = result.name.toLowerCase();
  const normalizedCountry = (result.country || "").toLowerCase();
  const populationScore = Math.log10((result.population || 0) + 1);
  let score = populationScore;

  if (normalizedName === normalizedQuery) {
    score += 3;
  }

  if (normalizedName === "bali" && normalizedCountry === "indonesia") {
    score += 6;
  }

  return score;
}

function sortResultsByRegion(results, query) {
  const normalizedQuery = query.trim().toLowerCase();

  return [...results].sort((first, second) => {
    const firstExact = first.name.toLowerCase() === normalizedQuery ? 0 : 1;
    const secondExact = second.name.toLowerCase() === normalizedQuery ? 0 : 1;
    if (firstExact !== secondExact) {
      return firstExact - secondExact;
    }

    const popularityDifference = getPopularityScore(second, query) - getPopularityScore(first, query);
    if (Math.abs(popularityDifference) > 1) {
      return popularityDifference;
    }

    const rankingCoords = userCoords || DEFAULT_RANKING_COORDS;
    return getDistanceKm(rankingCoords, first) - getDistanceKm(rankingCoords, second);
  });
}

function getUserLocation() {
  if (!navigator.geolocation) {
    return Promise.resolve(null);
  }

  return new Promise((resolve) => {
    navigator.geolocation.getCurrentPosition(
      (position) => {
        resolve({
          latitude: position.coords.latitude,
          longitude: position.coords.longitude
        });
      },
      () => resolve(null),
      {
        enableHighAccuracy: false,
        timeout: 8000,
        maximumAge: 900000
      }
    );
  });
}

function isMisty(current) {
  return !weatherGroups.rain.has(current.weather_code)
    && !weatherGroups.clear.has(current.weather_code)
    && current.relative_humidity_2m >= 88
    && current.cloud_cover >= 85
    && current.wind_speed_10m <= 14;
}

function getClearVisualClass(current) {
  const hour = Number(current.time?.slice(11, 13));
  return Number.isFinite(hour) && hour >= 15 ? "weather-clear-evening" : "weather-clear-morning";
}

function setCondition(current) {
  const code = current.weather_code;
  const windSpeed = current.wind_speed_10m || 0;
  const isNight = current.is_day === 0;
  const isClear = weatherGroups.clear.has(code);
  const isCloudy = weatherGroups.cloudy.has(code);
  const isDrizzle = weatherGroups.drizzle.has(code);
  const isRain = weatherGroups.rain.has(code);
  const isStorm = weatherGroups.storm.has(code);
  const isHeavyPrecip = isRain || isStorm;
  const label = isNight && code === 0
    ? "Clear"
    : isNight && code === 1
      ? "Mostly clear"
    : isMisty(current)
    ? "Misty"
    : windSpeed >= 38 && !isHeavyPrecip
      ? "Windy"
      : labels.get(code) || "Weather";
  const isHot = current.temperature_2m > 35;
  const isNightCloudy = isNight && !isRain && isCloudy;
  const isFog = weatherGroups.fog.has(code) || isMisty(current) || isNightCloudy;
  const visualClass = isFog
    ? "weather-fog"
    : isHot && !isHeavyPrecip
    ? "weather-hot"
      : !isHeavyPrecip && isClear
      ? getClearVisualClass(current)
      : !isHeavyPrecip && isCloudy
      ? "weather-cloudy"
      : !isHeavyPrecip && isDrizzle
      ? "weather-drizzle"
      : isStorm || windSpeed >= 38
      ? "weather-storm"
      : "weather-rain";

  conditionEl.textContent = label;
  document.body.classList.remove(
    "weather-hot",
    "weather-clear",
    "weather-clear-morning",
    "weather-clear-evening",
    "weather-cloudy",
    "weather-drizzle",
    "weather-fog",
    "weather-storm",
    "weather-rain"
  );
  document.body.classList.add(visualClass);
  localStorage.setItem("weatherVisualClass", visualClass);
}

async function loadWeather(city) {
  setStatus(`Loading ${city.name}`);
  conditionEl.textContent = "Loading";

  const url = new URL("https://api.open-meteo.com/v1/forecast");
  url.search = new URLSearchParams({
    latitude: city.latitude,
    longitude: city.longitude,
    current: "temperature_2m,weather_code,wind_speed_10m,relative_humidity_2m,cloud_cover,is_day",
    temperature_unit: "celsius",
    wind_speed_unit: "kmh",
    timezone: "auto"
  });

  try {
    const response = await fetch(url);
    if (!response.ok) {
      throw new Error("Weather request failed");
    }

    const data = await response.json();
    const current = data.current;
    temperatureEl.innerHTML = formatTemperature(current.temperature_2m);
    setCondition(current);
    setLocation(city);
    setStatus(locationLabelEl.textContent);
  } catch (error) {
    conditionEl.textContent = "Unavailable";
    setStatus("Weather unavailable");
  }
}

function formatCity(result) {
  const parts = [result.name, result.country].filter(Boolean);
  return parts.join(", ");
}

function closeResults() {
  resultsEl.classList.remove("is-open");
  resultsEl.innerHTML = "";
  activeResultIndex = -1;
}

function openSearch() {
  searchOverlayEl.hidden = false;
  inputEl.value = currentCity.name;
  setStatus(locationLabelEl.textContent);
  inputEl.focus({ preventScroll: true });
  inputEl.select();
}

function closeSearch() {
  searchController?.abort();
  closeResults();
  searchOverlayEl.hidden = true;
  locationTriggerEl.focus();
}

function resultButtons() {
  return [...resultsEl.querySelectorAll(".result-button:not([disabled])")];
}

function setActiveResult(index) {
  const buttons = resultButtons();
  if (!buttons.length) {
    activeResultIndex = -1;
    return;
  }

  activeResultIndex = (index + buttons.length) % buttons.length;
  buttons.forEach((button, buttonIndex) => {
    const isActive = buttonIndex === activeResultIndex;
    button.classList.toggle("is-active", isActive);
    button.setAttribute("aria-selected", String(isActive));
  });
  buttons[activeResultIndex].scrollIntoView({ block: "nearest" });
}

function renderResults(results) {
  resultsEl.innerHTML = "";
  activeResultIndex = -1;

  if (!results.length) {
    resultsEl.innerHTML = '<button class="result-button" type="button" disabled>No cities found</button>';
    resultsEl.classList.add("is-open");
    return;
  }

  results.slice(0, 5).forEach((result) => {
    const button = document.createElement("button");
    button.type = "button";
    button.className = "result-button";
    button.setAttribute("role", "option");
    button.setAttribute("aria-selected", "false");
    button.textContent = formatCity(result);
    button.addEventListener("click", () => {
      const city = {
        name: result.name,
        country: result.country,
        latitude: result.latitude,
        longitude: result.longitude
      };
      closeResults();
      closeSearch();
      loadWeather(city);
    });
    resultsEl.append(button);
  });

  resultsEl.classList.add("is-open");
  setActiveResult(0);
}

async function searchCities(query) {
  const trimmedQuery = query.trim();
  if (trimmedQuery.length < 2) {
    closeResults();
    return;
  }

  searchController?.abort();
  searchController = new AbortController();
  setStatus("Searching");

  const url = new URL("https://geocoding-api.open-meteo.com/v1/search");
  url.search = new URLSearchParams({
    name: trimmedQuery,
    count: "10",
    language: "en",
    format: "json"
  });

  try {
    const response = await fetch(url, { signal: searchController.signal });
    if (!response.ok) {
      throw new Error("Search request failed");
    }

    const data = await response.json();
    renderResults(sortResultsByRegion(data.results || [], trimmedQuery));
    setStatus(locationLabelEl.textContent);
  } catch (error) {
    if (error.name === "AbortError") {
      return;
    }

    closeResults();
    setStatus("Search unavailable");
  }
}

searchForm.addEventListener("submit", (event) => {
  event.preventDefault();
  searchCities(inputEl.value);
});

locationTriggerEl.addEventListener("click", openSearch);

overlayCloseEl.addEventListener("click", closeSearch);

inputEl.addEventListener("input", () => {
  window.clearTimeout(inputEl.searchTimer);
  inputEl.searchTimer = window.setTimeout(() => searchCities(inputEl.value), 300);
});

inputEl.addEventListener("keydown", (event) => {
  if (!resultsEl.classList.contains("is-open")) {
    return;
  }

  if (event.key === "ArrowDown") {
    event.preventDefault();
    setActiveResult(activeResultIndex + 1);
  }

  if (event.key === "ArrowUp") {
    event.preventDefault();
    setActiveResult(activeResultIndex - 1);
  }

  if (event.key === "Enter" && activeResultIndex >= 0) {
    event.preventDefault();
    resultButtons()[activeResultIndex]?.click();
  }
});

document.addEventListener("click", (event) => {
  if (!event.target.closest(".search-overlay") && !locationTriggerEl.contains(event.target)) {
    closeResults();
  }
});

document.addEventListener("keydown", (event) => {
  if (event.key === "Escape" && !searchOverlayEl.hidden) {
    closeSearch();
  }
});

async function initWeather() {
  setStatus("Allow location");
  const coords = await getUserLocation();

  if (!coords) {
    loadWeather(DEFAULT_CITY);
    return;
  }

  userCoords = coords;
  loadWeather({
    name: "Current location",
    country: "",
    latitude: coords.latitude,
    longitude: coords.longitude
  });
}

initWeather();
