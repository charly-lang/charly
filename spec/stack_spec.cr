require "./spec_helper"
include CharlyTypes

describe Stack do

  it "declare, write and read variables" do
    top = Stack.new nil
    top.write("myvar", TNumeric.new(25_f64), true)
    top.write("othervar", TString.new("Hello World"), true)

    top.get("myvar").value.should eq(25_f64)
    top.get("othervar").value.should eq("Hello World")
  end

  it "writes to variables in a parent stack" do
    top = Stack.new nil
    top.write("myvar", TNull.new, true)

    child = Stack.new top
    child.write("myvar", TNumeric.new(50_f64))

    top.get("myvar").value.should eq(50_f64)
    child.get("myvar").value.should eq(50_f64)
  end

  it "variables defined in children are not accessable to parents" do
    top = Stack.new nil
    child = Stack.new top

    child.write("myvar", TNumeric.new(50_f64), true)

    threw = false
    begin
      top.get("myvar")
    rescue ex
      threw = true
    end

    threw.should eq(true)
  end

  it "variable type changes work" do
    top = Stack.new nil
    child = Stack.new top

    top.write("myvar", TNumeric.new(50_f64), true)
    child.get("myvar").value.should eq(50_f64)

    top.write("myvar", TString.new("Hello World"))
    child.get("myvar").value.should eq("Hello World")
  end

end
