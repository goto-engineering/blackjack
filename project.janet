(declare-project
 :name "blackjack"
 :description "Play Blackjack"
 :dependencies [])

(declare-source
 :source ["blackjack.janet"])

(declare-executable
  :name "blackjack"
  :entry "blackjack.janet"
  :install true)
