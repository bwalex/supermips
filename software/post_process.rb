bin = File.read(ARGV[0])
bytes = bin.unpack("C*").map { |x| "%02x" % x }
bytes.each_slice(4) { |b| puts b.join }
