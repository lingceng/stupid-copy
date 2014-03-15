require 'minitest/autorun'
require 'pathname'
require 'fileutils'
require_relative '../stupidc'

module TestUtils

  def touch(file_path)
      FileUtils.mkpath(File.dirname(file_path))
      File.open(file_path, 'w') { |f| f.puts file_path }
  end

  def rmdir_if_exist(dir_path)
    if FileTest.exist?(dir_path)
      FileUtils.remove_dir(dir_path)
    end
  end
end

describe Stupidc do
  include TestUtils

  
  before do
    @input = MiniTest::Mock.new
    @output = MiniTest::Mock.new

    @stupidc = Stupidc.new(@input, @output)


    @workspace = File.dirname(__FILE__) + '/workspace'
    @project = %{magicsale}

    @rp = RuleParser.new(@stupidc.get_rules(@project), @input, @output)

    @target = "#{@workspace}/#{@project}/target/#{@project}/magic_list.jsp"
    @src = "#{@workspace}/#{@project}/src/main/webapp/magic_list.jsp"
    
    @target2 = "#{@workspace}/#{@project}/target/#{@project}/WEB-INFO/classes/magic_list.xml"
    @src2 = "#{@workspace}/#{@project}/src/main/resources/magic_list.xml"

    rmdir_if_exist(@workspace)

  end

  after do
    rmdir_if_exist(@workspace)
  end

  describe "judge_build_name" do
    it "must return the buildname when path contains /target/buildname/" do
       @stupidc.judge_build_name(@target).must_equal 'magicsale'
    end
  end

  describe "copy" do
    it "should copy file to source when file is target" do
      touch @target
      @stupidc.copy(@target)
      assert FileTest.exist?(@src)
    end

    it "should copy file to source when file is target other case" do
      touch @target2
      @stupidc.copy(@target2)
      assert FileTest.exist?(@src2)
    end


    it "should copy file to target when  a buildname is given" do
      touch @src
      @stupidc.copy(@src, buildname: @project)
      assert FileTest.exist?(@target)
    end


    it "should copy file to target when  a buildname is given other case" do
      touch @src2
      @stupidc.copy(@src2, buildname: @project)
      assert FileTest.exist?(@target2)
    end

    it "should output fail info when :from is not exist" do
      touch @src

      @output.expect :puts, nil, [Stupidc::PATHNAME_REQUIRED]
      @stupidc.copy(@src)
      @output.verify
    end
  end

end

describe RuleParser do
  include TestUtils

  before do
    @input = MiniTest::Mock.new
    @output = MiniTest::Mock.new

    @rp = RuleParser.new([], @input, @output)
    @path = "workspace2/"
    @f = @path + "file1"
    @t = @path + "file2"

    rmdir_if_exist @path 
  end

  after do
    rmdir_if_exist @path 
  end

    it "should output fail info when :from is not exist" do

      @output.expect :puts, nil, [RuleParser::NOT_EXIST]
      @rp.do_copy(@f, @t)
      @output.verify
    end

    it "should output fail info when :to is existed" do
      touch @f
      touch @t

      @output.expect :puts, nil, [RuleParser::EXISTED]
      @rp.do_copy(@f, @t)
      @output.verify
    end

    it "should output copy info" do
      touch @f
      
      @output.expect :puts, nil, ["\n-- start copy -- "]
      @output.expect :puts, nil, ["-- from : #{@f} "]
      @output.expect :puts, nil, ["-- to : #{@t}"]
      @output.expect :puts, nil, ["-- end copy --"]
      @rp.do_copy(@f, @t)
      @output.verify
    end


end


