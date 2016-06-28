# raw = '[LIST]
# [*]Audio overhaul. Tons of new voice over and sound fx.
# [*]
# [*]Improved performance and reduced memory use.
# [*]
# [*]Using a Core Sample will now give you exclusive rights to claim the tile for 60 secs.
# [*]
# [*]Double clicking on the "Open Lobby" now creates a default lobby just like clicking on the Join Lobby button when the Open Lobby is selected.
# [*]
# [*]Players can new set which monitor they want the game to use in options.
# [*]
# [*]Updates for Portuguese, French, German, Polish, Russian, Spanish, Chinese and Korean languages.
# [/LIST]'

# raw = "[quote] It&#8217;s safe to say HITMAN is the biggest venture we&#8217;ve ever undertaken at Io-Interactive. Not just in terms of scope and ambition but also in terms of the size of the game world itself. The playable area and density of our locations goes beyond anything we&#8217;ve built before. We&#8217;re striving to create a series of living, breathing worlds in those locations and we get pretty obsessed about every detail that you&#8217;ll experience. [/quote]"

raw = 'Soren talks [URL="http://www.mohawkgames.com/2014/05/19/introducing-offworld-trading-company/"][U]more about Offworld on his blog[/U][/URL], and the [URL="http://offworldtrading.com"][U]official site[/U][/URL] has some tidbits as well.'

# raw.gsub!(/\[quote\](.+?)\[\/quote\]/im) { |quote|
#   quote.gsub!(/\[quote\](.+?)\[\/quote\]/im) { "\n#{$1}\n" }
#   quote.gsub!(/\n/) { "> #{$1}\n" }
# }

# raw.gsub!(/\[spoiler="?(.+?)"?\](.+?)\[\/spoiler\]/im) { "\n#{$1}\n[spoiler]#{$2}[/spoiler]\n" }
          #  \[spoiler="?(.+?)"?\](.+)\[\/spoiler\]


# raw.gsub!(/\[list\](.*?)\[\/list\]/im, '[ul]\1[/ul]')
# raw.gsub!(/\[list=1\](.*?)\[\/list\]/im, '[ol]\1[/ol]')
# # convert *-tags to li-tags so bbcode-to-md can do its magic on phpBB's lists:
# raw.gsub!(/\[\*\]\n/, '')
# raw.gsub!(/\[\*\](.*?)\n/, '[li]\1[/li]')

raw.gsub!(/\[url="?([^"]+?)"?\](.*?)\[\/url\]/i) { "[#{$2}](#{$1})" }
raw.gsub!(/\[url="?(.+?)"?\](.+)\[\/url\]/i) { "[#{$2}](#{$1})" }

puts raw
