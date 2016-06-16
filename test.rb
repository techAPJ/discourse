raw = '[URL="http://i.imgur.com/5fW5UmB.jpg"]
[IMG]http://i.imgur.com/5fW5UmB.jpg[/IMG][/URL]'

# raw = "[quote] It&#8217;s safe to say HITMAN is the biggest venture we&#8217;ve ever undertaken at Io-Interactive. Not just in terms of scope and ambition but also in terms of the size of the game world itself. The playable area and density of our locations goes beyond anything we&#8217;ve built before. We&#8217;re striving to create a series of living, breathing worlds in those locations and we get pretty obsessed about every detail that you&#8217;ll experience. [/quote]"

# raw.gsub!(/\[quote\](.+?)\[\/quote\]/im) { |quote|
#   quote.gsub!(/\[quote\](.+?)\[\/quote\]/im) { "\n#{$1}\n" }
#   quote.gsub!(/\n/) { "> #{$1}\n" }
# }

# raw.gsub!(/\[spoiler="?(.+?)"?\](.+?)\[\/spoiler\]/im) { "\n#{$1}\n[spoiler]#{$2}[/spoiler]\n" }
          #  \[spoiler="?(.+?)"?\](.+)\[\/spoiler\]

# raw.gsub!(/\[IMG\]\[IMG\](.+?)\[\/IMG\]\[\/IMG\]/i) { "[IMG]#{$1}[/IMG]" }
# raw.gsub!(/\[list\](.*?)\[\/list\]/im, '[ul]\1[/ul]')
# raw.gsub!(/\[\*\]/, '*')

raw.gsub!(/\[list\](.*?)\[\/list\]/m, '[ul]\1[/ul]')
raw.gsub!(/\[list=1\](.*?)\[\/list\]/m, '[ol]\1[/ol]')
# convert *-tags to li-tags so bbcode-to-md can do its magic on phpBB's lists:
raw.gsub!(/\[\*\](.*?)\n/, '[li]\1[/li]')

puts raw
