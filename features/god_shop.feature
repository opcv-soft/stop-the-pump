Feature: The night shop's tree  (round 8, docs/ROUND_8_PLAN.md)
  As a player, I want a deep tree where some upgrades need two others
  so that I plan a build across branches, not just down one line (serves: Advancement, Mastery).

  Scenario: Eight branches
    Then the tree has HEURES, MARKETING, ATTRACTIONS, PISTOLET, RÉSERVOIR, SERVICE, AMBIANCE and CAMION
    And each branch is bought in order from the centre out

  Scenario: Upgrades with two parents
    Given an upgrade that sits between two branches
    Then it stays locked until I own both of its parents
    And its tooltip names them
    When I own both
    Then I can buy it

  Scenario Outline: The new upgrades
    Given I own <upgrade>
    Then <effect>
    Examples:
      | upgrade            | effect                                                                     |
      | Jauge d'alarme     | the tank tells me how long it lasts to the hour, and warns me in the day   |
      | Achat en vrac      | a delivery costs 10% less when the tank is under 25%                       |
      | Citerne usagée     | a partial delivery (one I can't fully afford) raises the price half as much |
      | Contrat à terme    | every fourth delivery comes without a price rise                           |
      | Fenêtre au volant  | a car that waited over 3 s buys a coffee: +$1                              |
      | Soirée du hockey   | every 7th day is hockey night: 3 more cars waiting and more cars pull in   |
      | Carte fidélité     | every 5th car is a regular who tips double                                 |
      | Néons de nuit      | tips +30% after 19 h                                                       |
      | Hangar à drones    | a drone fill earns $2 more                                                 |
      | Cantine à patates  | cars wait 20% longer and every applause earns $2 more                      |
      | Prix affiché       | every sale pays 5% more                                                    |
      | Sabot de Denver    | a thief gets clamped: it can't flee and what it stole goes back in my tank |
      | Sabot de Denver II | a customer about to give up gets clamped: it stops and waits a while longer |

  # --- Round 10, batch E (playtest 9) ------------------------------------------------------------

  Scenario: DÉGÂTS, the spill branch  (opens after Gros réservoir)
    Given Litière à chat
    Then spills waste 25% less gas
    Given the Aspirateur gonflable
    Then every 4 s a second tube man sucks up the biggest puddle and puts 70% of it back in the tank
    Given Bec anti-goutte
    Then a drip under 50 cents no longer counts as Overfilled

  Scenario: MULTI-JET, the multi-fill branch  (opens after Bec large, playtest 10)
    Then Double pistolet fills two cars in the ring, Bec évasé grows the ring, Triple pistolet fills three
    Given the Chien de berger robot
    Then every 12 s a robot dog rounds my customers up in a tight circle around where the nozzle points
    And then they go back to their rounds
