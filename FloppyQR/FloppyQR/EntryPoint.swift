import Foundation

@main
enum EntryPoint {
    static func main() async {
        if CommandLine.argc > 1 {
            await CLI.run()
        } else {
            FloppyQRApp.main()
        }
    }
}
