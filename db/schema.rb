# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[7.1].define(version: 2025_11_12_070802) do
  create_table "battle_actions", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.bigint "battle_turn_id", null: false
    t.integer "actor_type", default: 0, null: false
    t.bigint "actor_id", null: false
    t.bigint "card_id"
    t.bigint "effect_id"
    t.integer "priority_value", default: 0, null: false
    t.integer "damage"
    t.integer "heal"
    t.text "notes"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["battle_turn_id", "priority_value"], name: "idx_ba_turn_priority"
    t.index ["battle_turn_id"], name: "index_battle_actions_on_battle_turn_id"
    t.index ["card_id"], name: "index_battle_actions_on_card_id"
    t.index ["effect_id"], name: "index_battle_actions_on_effect_id"
  end

  create_table "battle_hands", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.bigint "battle_id", null: false
    t.integer "owner_type", default: 0, null: false
    t.bigint "owner_id", null: false
    t.bigint "card_id", null: false
    t.integer "slot_index", default: 0, null: false
    t.boolean "consumed", default: false, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["battle_id", "owner_type", "owner_id", "slot_index"], name: "idx_bh_owner_slot", unique: true
    t.index ["battle_id"], name: "index_battle_hands_on_battle_id"
    t.index ["card_id"], name: "index_battle_hands_on_card_id"
  end

  create_table "battle_turns", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.bigint "battle_id", null: false
    t.integer "turn_no", null: false
    t.integer "player_hand_type", null: false
    t.integer "enemy_hand_type", null: false
    t.integer "first_attacker", default: 0, null: false
    t.integer "outcome", default: 0, null: false
    t.datetime "resolved_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["battle_id", "turn_no"], name: "index_battle_turns_on_battle_id_and_turn_no", unique: true
    t.index ["battle_id"], name: "index_battle_turns_on_battle_id"
  end

  create_table "battles", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.bigint "player_id", null: false
    t.bigint "enemy_id", null: false
    t.integer "status", default: 0, null: false
    t.integer "turns_count", default: 0, null: false
    t.json "flags", null: false
    t.datetime "started_at"
    t.datetime "ended_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "player_hp", default: 5, null: false
    t.integer "enemy_hp", default: 5, null: false
    t.index ["enemy_id"], name: "index_battles_on_enemy_id"
    t.index ["player_id"], name: "index_battles_on_player_id"
  end

  create_table "card_effects", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.bigint "card_id", null: false
    t.bigint "effect_id", null: false
    t.float "magnitude", default: 1.0
    t.integer "order_in_card", default: 0, null: false
    t.index ["card_id", "effect_id"], name: "index_card_effects_on_card_id_and_effect_id", unique: true
    t.index ["card_id"], name: "index_card_effects_on_card_id"
    t.index ["effect_id"], name: "index_card_effects_on_effect_id"
  end

  create_table "cards", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.string "name", null: false
    t.bigint "element_id"
    t.integer "hand_type", default: 0, null: false
    t.integer "power", default: 1, null: false
    t.integer "rarity", default: 0, null: false
    t.text "description"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["element_id"], name: "index_cards_on_element_id"
  end

  create_table "effects", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.string "name", null: false
    t.integer "kind", default: 0, null: false
    t.integer "priority", default: 0, null: false
    t.text "formula", null: false
    t.integer "duration_turns"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "elements", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.string "code", null: false
    t.string "name", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["code"], name: "index_elements_on_code", unique: true
  end

  create_table "enemies", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.string "name", null: false
    t.bigint "element_id"
    t.integer "base_hp", default: 5, null: false
    t.boolean "boss", default: false, null: false
    t.json "flags", null: false
    t.text "description"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["element_id"], name: "index_enemies_on_element_id"
  end

  create_table "npc_characters", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.string "name", null: false
    t.string "role"
    t.bigint "element_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["element_id"], name: "index_npc_characters_on_element_id"
  end

  create_table "npc_lines", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.bigint "npc_character_id", null: false
    t.integer "context", default: 0, null: false
    t.text "text", null: false
    t.bigint "effect_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["effect_id"], name: "index_npc_lines_on_effect_id"
    t.index ["npc_character_id"], name: "index_npc_lines_on_npc_character_id"
  end

  create_table "players", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.string "name", null: false
    t.bigint "element_id"
    t.integer "base_hp", default: 5, null: false
    t.json "meta", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["element_id"], name: "index_players_on_element_id"
  end

  add_foreign_key "battle_actions", "battle_turns"
  add_foreign_key "battle_actions", "cards"
  add_foreign_key "battle_actions", "effects"
  add_foreign_key "battle_hands", "battles"
  add_foreign_key "battle_hands", "cards"
  add_foreign_key "battle_turns", "battles"
  add_foreign_key "battles", "enemies"
  add_foreign_key "battles", "players"
  add_foreign_key "card_effects", "cards"
  add_foreign_key "card_effects", "effects"
  add_foreign_key "cards", "elements"
  add_foreign_key "enemies", "elements"
  add_foreign_key "npc_characters", "elements"
  add_foreign_key "npc_lines", "effects"
  add_foreign_key "npc_lines", "npc_characters"
  add_foreign_key "players", "elements"
end
