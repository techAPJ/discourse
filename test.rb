# s = '[quote="Wheatlies" post=1385]http://www.roblox.com/Super-secret-snowmen-tests-place?id=134400791
#
# Ruddev: 1 step ahead[/quote]'
#
#
# puts s
#
# # [QUOTE username]...[/QUOTE]
# s.gsub!(/\[quote (.*?)\](.+?)\[\/quote\]/im) { "[quote] #{$2} [/quote]" }
#
# # [quote="Andy" post=183]...[/QUOTE]
# # s.gsub!(/\[quote=([^;\]]+)\](.+?)\[\/quote\]/im) { "[quote] #{$1} [/quote]" }
# # => "[quote] \"Andy\" post=183 [/quote]"
#
# # '[quote="GollyGreg" post=1290]\n[b]Edit[/b] Were trying to keep the project small. I think its just going to be CloneTrooper, Ozzypig, Kuunan,  Quenty, and I. But I have to wait until Clone comes back on within an hour.[/quote]'.gsub!(/\[quote (.*?)\](.+?)\[\/quote\]/i) { "[quote] #{$2} [/quote]" }
#
#
# s.gsub!(/\[quote="?(.+?)"? post=?(.+?)?\](.+?)\[\/quote\]/im) { "[quote] #{$3} [/quote]" }
#
# s.gsub!(/\[quote=?(.+?)? post=?(.+?)?\](.+?)\[\/quote\]/im) { "[quote] #{$3} [/quote]" }
#
# puts s

# puts '[video width=425 height=344 type=youtube]qZIOAoEiIzw[/video]'.gsub!(/\[video (.*?) type=youtube\](.+?)\[\/video\]/im) { "\nhttps://www.youtube.com/watch?v=#{$2}\n" }

# puts '[url=http://wiki.roblox.com/index.php/Change_Log]client and website change log[/url]'.gsub!(/\[url="?(.+?)"?\](.+?)\[\/url\]/im) { "[#{$2}](#{$1})" }

puts '[spoiler=This spoiler has a name >.<]
Well isnt that neat
[/spoiler]'.gsub!(/\[spoiler="?(.+?)"?\](.+?)\[\/spoiler\]/im) { "#{$2}" }

# http://localhost:3000/t/where-do-the-roblox-developers-live/217/6
#
# [quote="Andy" post=1659][quote="BAUER102" post=1656][quote="Andy" post=1653]I'm not on that list! Where's the Brittish Isles?[/quote]
#
# there's europe for you, mr.andy
#
# By the way, I live in Germany. :)[/quote]
#
# No... it's kind of not. The United Kingdom is not in Europe, it's in the Brittish Isles. The Republic of Ireland is not in Europe, it's the the Brittish Isles... the Isle of man is not in Europe it is also in the Brittish Isles.[/quote]
#
# Europe, being a continent, is where the British Isles fall. There is no continent of "The British Isles."


# http://localhost:3000/t/battlestations-pc-specs-and-internet-thread/896/54
