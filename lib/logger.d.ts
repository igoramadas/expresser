/** Logger helper class to configure the Anyhow logging module. */
declare class Logger {
    /** Recursive arguments cleaner. */
    static argsCleaner(obj: any, index: any): void;
    /** Used as a preprocessor for the Anyhow logger. */
    static clean(args: any[]): any;
}
export = Logger;
