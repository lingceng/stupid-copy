require 'fileutils'


#
# handle file with rules
#
class RuleParser
  include FileUtils

  NOT_EXIST = "--- from path not exist!"
  EXISTED = "--- to path already exist!"

  attr_accessor :verbose

  def initialize(rules, input=STDIN, out=STDOUT)
    @rules = rules

    @input = input
    @output = out

    @all = false
    @verbose = true
  end



  def handle(path_param)
    @all = false

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
    @output.print msg
    input = @input.gets.strip

    return default if input.empty? 

    if input =~ /^y(es)?$/i
      :yes 
    elsif input =~ /^a(ll)?$/i
      :all
    else 
      :no
    end
  end

  def do_copy(src, target) 

    unless FileTest.exist? src
      @output.puts NOT_EXIST 
      return
    end

    if FileTest.exist?(target) && @all == false
      cmd = ask "-- #{target} existed, override? y(es)/all/no: "
      if cmd == :no
        @output.puts "-- skiped!" 
        @output.puts "" 
        return
      elsif cmd == :all
        @all = true
      end
    end


    if @verbose
      @output.puts "-- from : #{src} "
      @output.puts "-- to : #{target}" 
      @output.puts "" 
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

  def self.rules(buildname)
    [ { 
      from: '/src/main/resources', 
      to: "/target/#{buildname}/WEB-INF/classes"
    }, { 
      from: '/src/main/webapp', 
      to: "/target/#{buildname}"
    } ]
  end


  def load_parser(buildname)
    raise ArgumentError, PATHNAME_REQUIRED  if buildname == nil

    return @parser if @buildname == buildname

    @parser = RuleParser.new(Stupidc.rules(buildname))
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
