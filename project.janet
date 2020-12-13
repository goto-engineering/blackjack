(declare-project
 :name "blackjack"
 :description "Play Blackjack"
 :dependencies ["https://github.com/janet-lang/argparse.git"])

(declare-source
 :source ["blackjack.janet"])

(declare-executable
  :name "blackjack"
  :entry "blackjack.janet"
  :install true)
