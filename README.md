# ArcaneAI
**Utility AI Plugin for Godot 4.3+**

### Features
- A comprehensive graph interface to design, test, and visualize your AI logic.
  - **Inspector Integration:** Easily tweak your curves and inspect AI responses directly in the editor.
  - **AI Resource Editor:** Double-click any AI resource in the file manager to open it in the editor for seamless editing and visualization.
- **AI Resource:** Save your crafted AI as a reusable resource to integrate directly into your game.

> **Note:**
This is a **Work in Progress** plugin and requires more testing before being production-ready.

### Installation
1. Download the `.zip` file.
2. Extract the contents into `res://addons/ArcaneAI`.
3. Enable the plugin in your project settings.

## Getting Started

### How to Use ArcaneAI
After enabling the plugin, you’ll see a new graph interface in the editor. This is where you’ll design and visualize your AI behaviors.

#### Core Nodes:
- **AI:**
  The root node of your AI system. It handles decision-making and manages the overall AI logic.

- **Action:**
  Represents the specific actions or states of your AI, like *Attack*, *Eat*, or *Wander*.

- **Utility:**
  Defines how your AI measures different factors. You can enter custom expressions in a small code box to create unique logic for each utility.

- **Aggregate:**
  Combines multiple utilities and calculates their values using different methods (sum, average, product). This allows you to create more nuanced decision-making by combining factors.

Each node is interactive. Click on any node to see its configuration options, such as curves, in the Inspector.

> I will likely include new node types in the future, such as:
> - ActionPool, which is a group of actions with the same utility, but has multiple actions, and has a strategy to choose the action.
> - Simplified Utilities that target specific attributes.
> - Expanded Aggregations with curves, and custom aggregation functions.
> - A node that allows you to import saved graphs.

#### Example Graph:

```plaintext
AI
  └─ Idle
      └─ Utility
  └─ Eat
      └─ Aggregate
          ├─ hungry
          └─ has_food
  └─ Find Food
      └─ Utility: hungry
  └─ Fight
      └─ Utility: player_dist <= attack_range
```

### Testing Your AI
To test your AI setup:
1. Select the AI node and click the **Test** button.
2. A new interface will appear in the Inspector, allowing you to choose a resource type for testing. Suggested resources from your project will be listed for convenience.
3. The plugin will instantiate the resource, link it to the AI, and let you adjust input values.
4. The graph will visually highlight the AI's decisions, while the Inspector displays the weights of all actions, making it easy to understand how your AI is responding.

### Tips for Building AI with ArcaneAI

- It's good practice to start with lower curve values. This helps you create more granular and controlled behaviors. For example, setting the maximum value for `Find Food` to `0.3` and `Eat` to `0.4` ensures that both nodes can respond to the `hungry` utility with appropriate nuance. This enables you to have actions that should always happen with a value of `1.0`, high prority in the range of `0.8 - 0.9`, and low priority like `0.1 - 0.2`.

- Always include a low-priority action like *Idle* with a linear curve value (e.g., `0.001`). This serves as a baseline, preventing the AI from taking actions based on insignificant changes in utility values.

- When using an `Aggregate` node with the `Product` method, any utility with a value of `0` will effectively disable the entire set of actions under that aggregate. This behavior is not a limitation but a helpful feature. For instance, if you want your AI to avoid fighting when it's not healthy, adding a health-related utility to the *Fight* action’s aggregate ensures that, when health drops to zero, the product of the utilities becomes zero, making the AI focus on other actions.

This allows you to create dynamic behaviors and fine-tune how your AI responds to different situations, ensuring it acts intelligently and in line with the scenarios you’ve crafted.

### Future Plans
- Make documentation, and improve this readme.
- Add more info to the display so you have more information about the decisions being made by your AI
- Improve UI feel, add shortcuts, and streamline adding new nodes.
- Add a new node type that allows you to load a saved scene as a subgraph (Because why repeat yourself right?) and possibly extend existing ones, similar to inheriting from a normal scene.
