require "./chalk/*"

module Chalk
    regex = /([^.]+)\.chalk/
    source_dir = "programs"
    dest_dir = "out"

    Dir.mkdir_p dest_dir
    exit if !File.directory? source_dir
    Dir.new(source_dir)
        .children
        .compact_map { |it| regex.match(it) }
        .each do |match|
        config = Ui::Config.new file: (source_dir + File::SEPARATOR + match[0]),
                                output:  (dest_dir + File::SEPARATOR + match[1] + ".ch8"),
                                loglevel: Logger::Severity::ERROR,
                                mode: Ui::OutputMode::Binary
        compiler = Compiler::Compiler.new config
        begin
            compiler.run
        rescue e
            puts "Exception compiling #{match[0]}"
        end
    end
end
