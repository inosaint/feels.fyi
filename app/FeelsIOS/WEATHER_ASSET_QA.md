# Weather Asset QA

- Keep phone background assets portrait-safe at 1290 x 2796 or an equivalent portrait ratio.
- If a source image is square, verify the subject still reads after `scaledToFill` center-cropping on portrait phones and iPads.
- Every `WeatherVisual` must have one iOS asset, one fallback color, and one preview state before release.
- Check clear morning, clear evening, hot, cloudy, fog, drizzle, rain, and storm after any asset replacement.
