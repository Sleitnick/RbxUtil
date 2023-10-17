declare namespace Log {
	type Level = number;
	type TimeUnit = number;

	interface Constructor {
		readonly Level: Record<"Trace" | "Debug" | "Info" | "Warning" | "Error" | "Fatal", number>;
		readonly TimeUnit: Record<
			"Milliseconds" | "Seconds" | "Minutes" | "Hours" | "Days" | "Weeks" | "Months" | "Years",
			number
		>;

		new (): Log;
	}
}

interface LogItem {
	Every(n: number): this;
	AtMostEvery(n: number, timeUnit: Log.TimeUnit): this;
	Throw(): this;
	Log(message: string, customData?: unknown): void;
	Assert(condition: boolean, ...args: unknown[]): void;
	Wrap(): (...args: Parameters<LogItem["Log"]>) => void;
}

interface Log {
	At(level: Log.Level): LogItem;
	AtTrace(): LogItem;
	AtDebug(): LogItem;
	AtInfo(): LogItem;
	AtWarning(): LogItem;
	AtError(): LogItem;
	AtFatal(): LogItem;
	Assert(condition: boolean, ...args: unknown[]): void;
}

declare const Log: Log.Constructor;

export = Log;
