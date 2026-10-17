extends Node

#Emitted by BottomPartition (Action Over button), EnemyAI
#Listeners: TurnManager
signal action_ended()

#Emitted by BottomPartition (Turn Over button)
#Listeners: TurnManager
signal turn_ended()

#Emitted by Character
#Listeners: Adventure, Portrait, EnemyPortrait, CombatMap
signal character_died(character: Character)

#Emitted by GameView, TurnManager
#Listeners: Adventure, Character, ActionBar, EnemyAI
#new_character is null when no one is acting (emitted at encounter end) — handle null.
signal acting_character_changed(new_character: Character)

#Emitted by TurnManager
#Listeners: BottomPartition
signal phase_changed(phase: int)

#Emitted by TurnManager
#Listeners: BottomPartition
signal turn_changed(turn: int)

#Emitted by TurnManager
#Listeners: BottomPartition, Portrait
signal mode_changed(new_mode: EnumService.Mode)

#Emitted by Portrait
#Listeners: Adventure
signal portrait_selected(character: Character)

#Emitted by InputHandler when the player left-clicks the map
#Listeners: Adventure
signal select_clicked(nodes: Array[Node], cell: Vector2i)

#Emitted by InputHandler when the player right-clicks the map
#Listeners: Adventure
signal action_clicked(nodes: Array[Node], cell: Vector2i)

#Emitted by InputHandler when the mouse hovers over the map
#Listeners: Adventure
signal hover_changed(nodes: Array[Node], cell: Vector2i)

#Emitted by Adventure
#Listeners: CombatMap
signal command_routed(command: ActionCommand)
