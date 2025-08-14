import { pageTitle } from 'ember-page-title';
import { on } from '@ember/modifier';
import { tracked } from '@glimmer/tracking';
import Component from '@glimmer/component';

export default class Application extends Component {
  @tracked wordList = [];

  submitWord = (e) => {
    if (e.key === 'Enter') {
      this.wordList = [...this.wordList, this.generateTiles(e.target.value)];
      e.target.value = '';
    }
  };

  /**
   * Creates an array of tile objects to spell out a word.
   * @returns {Record[]} The type of tile.
   */
  generateTiles(word) {
    const finalWord = [];

    word.split('').forEach((letter, i) => {
      const type = this.randomizeType(i === word.length - 1);

      finalWord.push({
        letter: letter.toUpperCase(),
        type,
        ...(type === 'diamond' && { bonus: this.randomNumber() }),
      });
    });

    return finalWord;
  }

  /**
   * Randomly selects a type for the tile.
   * @returns {string} The type of tile.
   */
  randomizeType(lastLetter) {
    const types = ['normal', 'gold', 'emerald', 'diamond', 'dotted'];
    const weights = lastLetter ? [50, 5, 5, 5, 35] : [60, 20, 10, 8, 2]; // Adjust weights as needed
    const totalWeight = weights.reduce((a, b) => a + b, 0);
    const rand = Math.random() * totalWeight;
    let sum = 0;
    for (let i = 0; i < types.length; i++) {
      sum += weights[i];
      if (rand < sum) {
        return types[i];
      }
    }
    return types[0];
  }

  randomNumber() {
    // Generates a random multiple of 5 from 0 up to 95 (inclusive)
    const max = 100 / 5; // 20
    return Math.floor(Math.random() * max) * 5;
  }

  <template>
    {{pageTitle "Mathplay"}}

    {{outlet}}

    <input
      type="text"
      id="word"
      placeholder="Add Word..."
      {{on "keydown" this.submitWord}}
    />

    <p>Dotted (red) tiles multiply the
      <strong>Word Score</strong>
      by 2. Gold multiplies
      <strong>Word Score</strong>
      by the amount of Gold tiles. Emerald tiles multiply the
      <strong>letter score</strong>
      by 4, and Diamond tiles add their bonus to the
      <strong>letter score</strong>. Bonuses (orange) are added separately.</p>

    <ol>
      {{#each this.wordList as |word|}}
        <li>
          {{#each word as |tile|}}
            <span
              class="tile"
              data-type={{tile.type}}
              data-bonus={{tile.bonus}}
            >
              <span class="score" data-letter={{tile.letter}}></span>
              {{tile.letter}}
            </span>
          {{/each}}
        </li>
      {{/each}}
    </ol>
  </template>
}
