class A
  def to_s
    puts 'hello'
  end
end

class B <A
end

class C <B
end

a = B.new
a.to_s
c = C.new
c.to_s