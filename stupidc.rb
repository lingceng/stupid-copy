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



  def handle(path)
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


  def do_copy(src, target) 

    unless FileTest.exist? src
      @output.puts NOT_EXIST 
      return
    end

    if FileTest.exist? target 
      @output.puts EXISTED 
      return
    end

    @output.puts "\n-- start copy -- " 
    @output.puts "-- from : #{src} "
    @output.puts "-- to : #{target}" 

    mkpath(File.dirname(target))
    copy(src, target)

    @output.puts "-- end copy --" 
  end
  

end

class Stupidc
  PATHNAME_REQUIRED = "--- buildname parameter required!"

  def initialize(input=STDIN, out=STDOUT)
    @input = input
    @output = out
  end

  def judge_build_name(path)
    path[%r{/target/(\w+)/}, 1]
  end

  def get_rules(buildname)
    rules = [ { 
      from: '/src/main/resources', 
      to: "/target/#{buildname}/WEB-INFO/classes"
    }, { 
      from: '/src/main/webapp', 
      to: "/target/#{buildname}"
    } ]
  end

  def get_parser(buildname)
    return @parser if @buildname == buildname
    @buildname = buildname

    @parser = RuleParser.new(get_rules(@buildname))
  end

  def copy(path, opts = {})
    # capatible for windows path
    path.gsub!('\\', '/')

    buildname = judge_build_name(path) || opts[:buildname]

    if buildname == nil
      @output.puts PATHNAME_REQUIRED
      return
    end

    @paser = get_parser(buildname) 
    @parser.handle(path)
  end
end
