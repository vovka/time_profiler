require 'method_source'
# require 'byebug'
require 'debugger'
require 'pp'

class LinesProfiler
  def self.profile!(klass, instance_method)
    @counter = 0
    body = klass.instance_method(instance_method).source.split("\n")
    evaluation = <<-EOR
      alias_method :old_#{instance_method}, :#{instance_method}

      #{body[0]}
        start_at = Time.now
        #{body[1..-2].inject('') { |memo, str| 
          memo += 'result = ' if str !~ /^\s*(\{|end|#|return|else|elsif)/
          memo += str + tick(klass, instance_method) 
        }}
        result
      end
    EOR

    print evaluation

    klass.class_eval evaluation
  end

  def self.tick(klass, instance_method)
    @counter ||= 0
    <<-EOR
      
      time = Time.now - start_at
      p("#{klass}:#{instance_method}:#{@counter+=1} executed in " + time.to_s)
      p method(__method__).parameters.map { |arg| eval(arg[1].to_s) } if time > 0.09
      start_at = Time.now
      result if defined? result

    EOR
  end
end

# class Test1
#   def test
#     p 1
#     sleep 1
#     p 2
#     sleep 2
#     p 3
#     sleep 3
#   end
# end

# LinesProfiler.profile! Test1, :test

# test = Test1.new
# test.test
