require 'fileutils'


#
# handle file with rules
#
class RuleParser
  include FileUtils

  NOT_EXIST = "--- from path not exist!"
  EXISTED = "--- to path already exist!"


  def initialize(rules, input=STDIN, out=STDOUT)
    @rules = rules

    @input = input
    @output = out
  end



  def handle(path_param)
    Dir[path_param].each do |path|

      @rules.each do |r| 
        if path[ r[:from] ]
          target = path.sub(r[:from], r[:to]) 
        elsif path[ r[:to] ]
          target = path.sub(r[:to], r[:from]) 
        end

        if target != nil 
          do_copy(path, target)
          break
        end
      end

    end
  end

  def ask(msg, default=:yes) 
    @output.puts msg
    input = @input.gets.strip

    return default if input.empty? 

    if input =~ /^ye?s?$/i
      :yes 
    else 
      :no
    end
  end

  def do_copy(src, target, verbose=true) 

    unless FileTest.exist? src
      @output.puts NOT_EXIST 
      return
    end

    if FileTest.exist? target 
      cmd = ask "-- #{target} existed, override? y(es)/no "
      if cmd == :no
        @output.puts "-- skiped!" 
        return
      end
    end

    if verbose
      @output.puts "-- from : #{src} "
      @output.puts "-- to : #{target}" 
    end
    
    dir = File.dirname(target)
    mkpath(dir) unless FileTest.exist? dir
    copy(src, target)

  end

end

class Stupidc
  PATHNAME_REQUIRED = "--- buildname parameter required!"

  def initialize(input=STDIN, output=STDOUT)
    @input = input
    @output = output
  end

  def judge_build_name(path)
    path[%r{/target/(\w+)/}, 1]
  end

  def compatible_windows_path(path)
    path.gsub('\\', '/')
  end

  def rules()
    [ { 
      from: '/src/main/resources', 
      to: "/target/#{@buildname}/WEB-INFO/classes"
    }, { 
      from: '/src/main/webapp', 
      to: "/target/#{@buildname}"
    } ]
  end


  def load_parser(buildname)
    raise ArgumentError, PATHNAME_REQUIRED  if buildname == nil

    return @parser if @buildname == buildname

    @buildname = buildname
    @parser = RuleParser.new(rules)
  end

  def copy(path, opts = {})
    path = compatible_windows_path(path)
    buildname = judge_build_name(path) || opts[:buildname]

    begin
      load_parser(buildname).handle(path)
    rescue ArgumentError => e
      @output.puts e.message
    end

  end
end
