
# Enter your Ruby code here

filename = "G:\\Gent\\AWG\\EDG\\grating_points_huannan.txt"
File.open(filename, "r").each_line do |line|
  data = line.split(/\t/)
  puts data
end