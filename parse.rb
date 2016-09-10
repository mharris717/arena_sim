require 'mharris_ext'
require 'open-uri'
require 'nokogiri'
load "main.rb"

def classes
  %w(mage rogue paladin shaman warlock druid warrior hunter priest)
end

def rarities
  %w(commons rares epics legendaries)
end

def doc
  $doc ||= Nokogiri::HTML(open("hearthtier.htm"))
end

def cards_for_class(cls)
  cards = doc.css("section.tierlist.#{cls}").css("ol.cards .card")
  cards.map do |c|
    card = parse_card_div(c)
    card.draft_class = cls
    card
  end
end

class Card
  include FromHash
  attr_accessor :name, :score, :draft_class, :card_class, :rarity, :bonus

  def to_s
    "#{name} #{score} #{draft_class} #{card_class} #{rarity} #{bonus}"
  end
end

class DraftCards
  include FromHash
  fattr(:cards) { [] }
  fattr(:by_rarity) do
    res = Hash.new { |h,k| h[k] = [] }
    cards.each do |c|
      for_draft = [c]
      if c.card_class != 'neutral'
        for_draft = for_draft*4
      end
      if c.bonus
        for_draft = for_draft*3
      end
      res[c.rarity] += for_draft
    end
    res
  end
  def choice_rarity
    i = rand(30)
    if i < 20
      :commons
    elsif i < 27
      :rares
    elsif i < 29
      :epics
    else
      :legendaries
    end
  end

  def choices
    rarity = choice_rarity
    res = []
    while res.size < 3
      c = by_rarity[rarity.to_s].rand_el
      res << c unless res.include?(c)
    end
    res
  end

  def choice
    choices.sort_by { |x| x.score }.last
  end

  class << self
    def for_class(c)
      all = cards = cards_for_class(c)
      if bans?
        cards = cards.reject { |x| bans.include?(x.name) }
        # puts "#{all.size} -> #{cards.size}"
      end
      new(cards: cards)
    end
  end
end

def parse_card_div(div)
  name_dt = div.css("dt")[0]
  full_name = name_dt.text.strip.split("\n")
  name = full_name[0]
  bonus = (full_name[1] == "New")
  score = div.css(".score").text.strip.gsub("↓","").to_i
  cls = classes.find do |c|
    name_dt['class'].split(' ').include?(c)
  end || 'neutral'
  rarity = rarities.find do |c|
    name_dt['class'].split(' ').include?(c)
  end
  Card.new(name: name, score: score, card_class: cls, rarity: rarity, bonus: bonus)
end

def bans
  "Forgotten Torch
  Snowchugger
  Faceless Summoner
  Goblin Auto-Barber
  Undercity Valiant
  Vitality Totem
  Dust Devil
  Totemic Might
  Ancestral Healing
  Dunemaul Shaman
  Windspeaker
  Anima Golem
  Sacrificial Pact
  Curse of Rafaam
  Sense Demons
  Void Crusher
  Reliquary Seeker
  Succubus
  Savagery
  Poison Seeds
  Soul of the Forest
  Mark of Nature
  Tree of Life
  Astral Communion
  Warsong Commander
  Bolster
  Charge
  Bouncing Blade
  Axe Flinger
  Rampage
  Ogre Warmaul
  Starving Buzzard
  Call Pet
  Timber Wolf
  Cobra Shot
  Lock and Load
  Dart Trap
  Snipe
  Mind Blast
  Shadowbomber
  Lightwell
  Power Word: Glory
  Confuse
  Convert
  Inner Fire".split("\n").map { |x| x.strip }
end

def bans?
  !!$bans
end

# all = classes.map { |x| cards_for_class(x) }.flatten
# bans.each do |ban|
#   raise ban unless all.map { |x| x.name }.include?(ban)
# end


def breakdown(cls)
  $bans = false
  # puts cls
  cards = DraftCards.for_class(cls)
  choices = 500000.of { cards.choice.score }.sort.reverse
  before = choices.average
  # puts "  #{cls.lpad(10)} No Bans: #{choices.average}, Median: #{choices[50000]} #{choices[80000...100000].average}"
  $bans = true
  cards = DraftCards.for_class(cls)
  choices = 500000.of { cards.choice.score }.sort.reverse
  after = choices.average
  puts "#{cls.lpad(10)} #{before.round(2)} -> #{after.round(2)}"
  #puts "#{cls.lpad(10)} With Bans: #{choices.average}, Median: #{choices[50000]} #{choices[80000...100000].average}"
end

classes.each do |c|
  breakdown c
end