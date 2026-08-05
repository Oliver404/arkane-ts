import { Scene2D } from '../scene/Scene2D'

export class SceneManager {
  private currentScene?: Scene2D

  setScene(scene: Scene2D | null) {
    if (this.currentScene) {
      this.currentScene.onExit()
    }

    this.currentScene = scene ?? undefined

    if (scene) {
      scene.onEnter()
    }
  }

  clear() {
    this.setScene(null)
  }

  getCurrentScene(): Scene2D | undefined {
    return this.currentScene
  }

  update() {
    this.currentScene?.update()
  }
}
