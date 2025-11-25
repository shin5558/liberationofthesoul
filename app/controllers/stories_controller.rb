class StoriesController < ApplicationController
  before_action :set_player
  before_action :set_progress

  # スタート〜プロローグ表示
  def prologue
    # 無属性カード1枚配布処理をここで呼んでもOK
    # 例: @player.give_neutral_card_once!
    @progress.update!(current_step: 'branch1')
  end

  # 分岐1選択画面（ゴブリン or 盗賊）
  def branch1_choice
    # ここでは単に選択肢ボタンを出すだけ
  end

  # 「茂みのあたりを調べる」→ ゴブリン戦へ
  def go_goblin
    @progress.update!(current_step: 'goblin_battle')
    redirect_to new_battle_path(player_id: @player.id, enemy_type: 'goblin')
  end

  # 「悲鳴の方へ向かう」→ 盗賊戦へ
  def go_thief
    @progress.update!(current_step: 'thief_battle')
    redirect_to new_battle_path(player_id: @player.id, enemy_type: 'thief')
  end

  # ゴブリン戦勝利後に呼ばれる想定
  def after_goblin
    @progress.update!(current_step: 'after_goblin')
    # 将来的に：馬車をあさる → 無属性カード付与
  end

  # 盗賊戦勝利後に呼ばれる想定
  def after_thief
    flags = @progress.flags_hash
    flags['helped_victim'] = true # 真エンド条件1
    @progress.update!(current_step: 'after_thief', flags: flags)
  end

  # 分岐2（レジスタンス：門番か将軍か）
  def branch2_choice
    # 壁下へ行く / 将軍のいるエリアへ行く の選択肢表示
  end

  def go_gatekeeper
    @progress.update!(current_step: 'gatekeeper_battle')
    redirect_to new_battle_path(player_id: @player.id, enemy_type: 'gatekeeper')
  end

  def go_general
    @progress.update!(current_step: 'general_battle')
    redirect_to new_battle_path(player_id: @player.id, enemy_type: 'general')
  end

  def after_gatekeeper
    @progress.update!(current_step: 'warehouse')
  end

  def after_general
    flags = @progress.flags_hash
    flags['defeated_general'] = true # 真エンド条件2
    @progress.update!(current_step: 'warehouse', flags: flags)
  end

  def warehouse
    # 倉庫イベント（無属性カード配布など）
    @progress.update!(current_step: 'demonlord_intro')
  end

  def demonlord_intro
    # 魔王前の会話
  end

  def go_demonlord
    @progress.update!(current_step: 'demonlord_battle')
    redirect_to new_battle_path(player_id: @player.id, enemy_type: 'demonlord')
  end

  # 魔王戦後、エンディング振り分け
  def ending
    flags = @progress.flags_hash
    @true_end =
      flags['helped_victim'] &&
      flags['defeated_general'] &&
      flags['no_game_over'] # これはどこかで管理する想定

    if @true_end
      render :ending_true
    else
      render :ending_normal
    end
  end

  private

  def set_player
    pid = session[:player_id] || params[:player_id]
    @player = Player.find_by(id: pid)
  end

  def set_progress
    @progress = StoryProgress.find_or_create_by!(player: @player)
  end
end
