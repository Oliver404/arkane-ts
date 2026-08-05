import { Entity } from '../scene/Entity'

export type DespawnCondition = (entity: Entity) => boolean

export class DespawnSystem {
  private condition: DespawnCondition

  constructor(condition: DespawnCondition) {
    this.condition = condition
  }

  update(entities: Entity[], remove: (e: Entity) => void): void {
    for (let i = entities.length - 1; i >= 0; i--) {
      const entity = entities[i]
      if (this.condition(entity)) {
        remove(entity)
      }
    }
  }
}
