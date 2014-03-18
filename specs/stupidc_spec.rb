require 'minitest/autorun'
require 'pathname'
require 'fileutils'
require_relative '../stupidc'

module MyFileUtil

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
  include MyFileUtil


  before do
    @input = MiniTest::Mock.new
    @output = MiniTest::Mock.new

    @stupidc = Stupidc.new(@input, @output)


    @workspace = File.expand_path('../workspace', __FILE__)
    @project = %{magicsale}

    @target = "#{@workspace}/#{@project}/target/#{@project}/magic_list.jsp"
    @src = "#{@workspace}/#{@project}/src/main/webapp/magic_list.jsp"
  end

  describe "judge_build_name" do
    it "must return the buildname when path contains /target/buildname/" do
      @stupidc.judge_build_name(@target).must_equal 'magicsale'
    end
  end

  describe "copy" do
    before do
      @target2 = "#{@workspace}/#{@project}/target/#{@project}/WEB-INFO/classes/magic_list.xml"
      @src2 = "#{@workspace}/#{@project}/src/main/resources/magic_list.xml"

      rmdir_if_exist(@workspace)
    end

    after do
      rmdir_if_exist(@workspace)
    end


    it "should copy file to source when file is target" do
      touch @target
      @stupidc.copy(@target)
      FileTest.exist?(@src).must_equal true


      touch @target2
      @stupidc.copy(@target2)
      FileTest.exist?(@src2).must_equal true
    end


    it "should copy file to target when a buildname is given" do
      touch @src
      @stupidc.copy(@src, buildname: @project)
      FileTest.exist?(@target).must_equal true

      touch @src2
      @stupidc.copy(@src2, buildname: @project)
      FileTest.exist?(@target2).must_equal true
    end

    it "should expand pattern" do
      target3  = "#{@workspace}/#{@project}/target/#{@project}/magic_list3.jsp"
      src3  = "#{@workspace}/#{@project}/src/main/webapp/magic_list3.jsp"
      path  = "#{@workspace}/#{@project}/target/#{@project}/*.jsp"

      touch @target
      touch target3

      @stupidc.copy(path)
      FileTest.exist?(@src).must_equal true
      FileTest.exist?(src3).must_equal true
    end



    it "should output error message info when exception" do
      touch @src
      "#{@workspace}/#{@project}/target/#{@project}/magic_list.jsp"
      @output.expect :puts, nil, [Stupidc::PATHNAME_REQUIRED]
      @stupidc.copy(@src)
      @output.verify
    end

    it "should raise error when buildname is nil" do
      proc { @stupidc.load_parser(nil) }.must_raise  ArgumentError
    end

  end

end

describe RuleParser do
  include MyFileUtil

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

    @output.expect :puts, nil, ["-- from : #{@f} "]
    @output.expect :puts, nil, ["-- to : #{@t}"]
    @rp.do_copy(@f, @t)
    @output.verify
  end



end


