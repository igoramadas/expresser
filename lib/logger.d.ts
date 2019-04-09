/** Logger helper class to configure the Anyhow logging module. */
declare class Logger {
    static argsCleaner(obj: any, index: any): void;
    static clean(args: any[]): any[];
}
export = Logger;
