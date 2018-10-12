require 'json'

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# Given a 6-digit ID what is the best way to map that ID
# into a dir structure to achieve fastest read/writes?
# eg given id == 'ejdqsc'
# 3/3   -> 'ejd/qsc'
# 2/2/2 -> 'ej/dq/sc'
# 1/1/1/1/1/1 -> 'e/j/d/q/s/c'
# etc
#
# Assuming an alphabet of 0-9 (10 letters):
# 3/3 means fewer dirs (2)
# but more entries to look through at each dir (10^3==1000)
#
# 1/1/1/1/1/1 means more dirs (6)
# but less entries to look though at each dir (10^1==10)
#
# This program gathers data to help make a decision.
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

def cla(key, default)
  arg = ARGV.detect{ |arg| arg.start_with?("--#{key}=")}
  if arg
    arg.split('=')[1]
  else
    default
  end
end

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

def id_size
  # The number of digits in the ID
  cla('id_size','6').to_i
end

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

def all_max
  # The maximum number of dirs to create at a given 'level'.
  # For example, suppose a split of 6 being timed is 5/1
  # then given an alphabet of 0-9 there are
  # 10^5 == 100,000 possible dirs for the 'level-0' 5-digit dir.
  # But all_max=1000 would reduce 10^5 down to 1000
  # As all_max increases to does the chance of filling the disk.
  cla('all_max','2000').to_i
end

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

def sample_max
  # The number of dirs, at each level, to keep 'alive'
  # for the next level.
  # For example, suppose a split of 6 is 3/3
  # then assuming an alphabet of 0-9
  # at the first level there are 1000 dirs.
  # A sample_max of 5 means only 5 of these dirs are selected
  # to become the base-dir for the dirs at the next level.
  # This would result in dirs that are created,
  # and actually contain a file, of (ignoring shuffling)
  # 000/000, 000/001, 000/002, 000/003, 000/004
  # 001/000, 001/001, 001/002, 001/003, 001/004
  # 002/000, 002/001, 002/002, 002/003, 002/004
  # 003/000, 003/001, 003/002, 003/003, 003/004
  # 004/000, 004/001, 004/002, 004/003, 004/004
  # As sample_max increases so does the chance of filling the disk.
  cla('sample_max','3').to_i
end

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

def alphabet
  '0123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ'
end

# = = = = = = = = = = = = = = = = = = = = = =

$cache_all_dir_names = []

def all_dir_names(digits)
  # eg digits==1 --> [0..9]
  # eg digits==2 --> [00..99]
  # eg digits==3 --> [000..999]
  $cache_all_dir_names[digits] ||=
    make_all_dir_names(digits)
end

# - - - - - - - - - - - - - - - - - - - - - - -

def make_all_dir_names(digits)
  max = [alphabet.size**digits, all_max].min
  (0...max).map { |n| zerod(n, digits) }
           .shuffle
end

def zerod(n, digits)
  base = alphabet.size
  res = ''
  loop do
    index = n % base
    letter = alphabet[index]
    res += letter
    n /= base
    break if n == 0
  end
  res += '0' * (digits - res.length)
  res.reverse
end

# = = = = = = = = = = = = = = = = = = = = = =

def partitions(n, max = n)
  # See https://stackoverflow.com/questions/10889379
  if n == 0
    [[]]
  else
    [max, n].min.downto(1).flat_map do |i|
      partitions(n-i, i).map { |rest| [i, *rest] }
    end
  end
end

# - - - - - - - - - - - - - - - - - - - - - - -

def timed
  started = Time.now
  result = yield
  finished = Time.now
  duration = (finished - started)
  [duration,result]
end

# - - - - - - - - - - - - - - - - - - - - - - -

def sample_dirs(split)
  # eg split = [3,2,1]
  tmp =  '/tmp/id_splits'
  `rm -rf #{tmp} && mkdir -p #{tmp}`
  verbose('% 20s' % split.inspect+' ')
  sample = [ tmp ]
  split.each_with_index do |digits,index|
    verbose(" L#{index}(#{digits})")
    rhs_dirs = all_dir_names(digits)
    all_dirs = splice_dirs(sample, rhs_dirs).flatten(1)
    make_dirs(all_dirs)
    sample_dirs = rhs_dirs.sample(sample_max)
    sample = all_dirs.select { |dir| in_sample?(dir, sample_dirs) }
  end
  write_files(sample)
  verbose("\n")
  sample
end

# - - - - - - - - - - - - - - - - - - - - - - -

def splice_dirs(lhs, rhs)
  progress = ProgressBar.new('S', lhs.size * rhs.size)
  lhs.map do |a|
    rhs.map do |b|
      progress.show
      a + '/' + b
    end
  end
end

# - - - - - - - - - - - - - - - - - - - - - - -

def make_dirs(dirs)
  progress = ProgressBar.new('M', dirs.size)
  dirs.each do |dir|
    progress.show
    `mkdir #{dir}`
  end
end

# - - - - - - - - - - - - - - - - - - - - - - -

def write_files(dirs)
  progress = ProgressBar.new('W', dirs.size)
  dirs.each do |dir|
    progress.show
    IO.write(dir + '/info.txt', 'hello')
  end
  verbose("(#{dirs.size}) #{dirs[1]}")
end

# - - - - - - - - - - - - - - - - - - - - - - -

def in_sample?(dir, sample_dirs)
  sample_dirs.any? { |sample| dir.end_with?(sample) }
end

# - - - - - - - - - - - - - - - - - - - - - - -

class ProgressBar
  def initialize(prefix,max)
    @prefix = prefix
    @max = max
    @count = 0
    verbose(percent)
  end
  def show
    @count += 1
    verbose(backspaced(percent))
  end
  private
  def percent
    value = ((@count / @max.to_f) * 100).to_i
    ' ' + @prefix + (':%3d' % value) + '%'
  end
  def backspaced(msg)
    ("\b" * msg.length) + msg
  end
end

# - - - - - - - - - - - - - - - - - - - - - - -

def verbose(s)
  STDOUT.print(s)
  STDOUT.flush
end

# - - - - - - - - - - - - - - - - - - - - - - -

def average_of(times)
  '%.07f' %  (times.reduce(:+) / times.size.to_f)
end

# - - - - - - - - - - - - - - - - - - - - - - -

def gather_times(splits)
  times = { m:{}, e:{}, r:{}, w:{} }
  splits.each do |split|
    times[:m][split] = []
    times[:e][split] = []
    times[:r][split] = []
    times[:w][split] = []
    sample_dirs(split).each do |dir|

      (0..10).each do |n|
        name = dir + '/' + n.to_s

        time,result = timed { make(name) }
        unless result === true
          fail RuntimeError, "make(#{name}) == #{result}"
        end
        times[:m][split] << time

        time,result = timed { exists?(name) }
        unless result === true
          fail RuntimeError, "exists?(#{name}) == #{result}"
        end
        times[:e][split] << time

        time,result = timed { write(name) }
        unless result == ('hello' * 500).size
          fail RuntimeError, "write(#{name}) == #{result}"
        end
        times[:w][split] << time

        time,result = timed { read(name) }
        unless result == 'hello' * 500
          fail RuntimeError, "read(#{name}) == #{result}"
        end
        times[:r][split] << time
      end
    end
  end
  times
end

# - - - - - - - - - - - - - - - - - - - - - - -

def make(dir)
  `mkdir #{dir}`
  true
end

def exists?(dir)
  File.directory?(dir)
end

def read(dir)
  IO.read(dir+'/info.txt')
end

def write(dir)
  IO.write(dir+'/info.txt', 'hello'* 500)
end

# - - - - - - - - - - - - - - - - - - - - - - -

def gather_splits
  partitions(id_size).collect { |p| p.permutation.sort.uniq }
                     .flatten(1)
                     .shuffle
end

# - - - - - - - - - - - - - - - - - - - - - - -

def gather_averages(splits, times)
  averages = { m:{}, e:{}, r:{}, w:{}, a:{} }
  splits.each do |split|
    mt = times[:m][split]
    et = times[:e][split]
    rt = times[:r][split]
    wt = times[:w][split]
    averages[:m][split] = average_of(mt)
    averages[:e][split] = average_of(et)
    averages[:r][split] = average_of(rt)
    averages[:w][split] = average_of(wt)
    averages[:a][split] = average_of(mt + et + rt + wt)
  end
  averages
end

# - - - - - - - - - - - - - - - - - - - - - - -

def show_averages(averages)
  puts
  show_sorted_averages('make',    averages[:m])
  show_sorted_averages('exists?', averages[:e])
  show_sorted_averages('read',    averages[:r])
  show_sorted_averages('write',   averages[:w])
  show_sorted_averages('all',     averages[:a])
  puts
end

# - - - - - - - - - - - - - - - - - - - - - - -

def show_sorted_averages(name, split_times)
  split_times.sort_by { |_split,time| time }
             .each { |split,time|
                t = '%.07f' % time.to_f
                puts "#{'% 8s' % name} #{t} <-- #{split}"
                # eg 0.020310 <-- [1, 1, 2]
             }
end

# - - - - - - - - - - - - - - - - - - - - - - -

def show_id_splits_times
  puts("all_max=#{all_max}")
  puts("sample_max=#{sample_max}")
  es = ARGV.detect{ |arg| arg.start_with?('--split=') }
  if es
    split = JSON.parse(es.split('=')[1])
    puts("id_size=#{split.reduce(:+)}")
    puts
    splits = [ split ]
  else
    puts("id_size=#{id_size}")
    puts
    splits = gather_splits
  end

  times = gather_times(splits)
  averages = gather_averages(splits, times)

  show_averages(averages)
end

# - - - - - - - - - - - - - - - - - - - - - - -

show_id_splits_times
