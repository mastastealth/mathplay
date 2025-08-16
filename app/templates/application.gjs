import { pageTitle } from 'ember-page-title';
import { on } from '@ember/modifier';
import { get } from '@ember/helper';
import { tracked } from '@glimmer/tracking';
import Component from '@glimmer/component';
import { debug } from '@ember/debug';
import QRCode from 'qrcode';

export default class Application extends Component {
  @tracked wordList = [];
  @tracked qrList = [];

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
    let wordScore = 0;
    let bonusScore = 0;
    let goldCount = 0;

    word
      .trim()
      .split('')
      .forEach((letter, i) => {
        const type = this.randomizeType(i === word.length - 1);
        const letterScore = this.getLetterScore(letter.toUpperCase());
        const bonus = 5 * this.wordList.length;

        wordScore += type === 'emerald' ? letterScore * 4 : letterScore;
        if (type === 'diamond') wordScore += bonus;
        if (type === 'gold') goldCount++;

        // Add bonus for longer words
        if (i > 11) bonusScore += 20;
        if (i > 9 && i <= 11) bonusScore += 15;
        if (i > 7 && i <= 9) bonusScore += 10;
        if (i >= 4 && i <= 7) bonusScore += 5;

        debug(
          `${i} -- Letter: ${letter.toUpperCase()}, Score: ${letterScore}, Word Score: ${wordScore}, Bonus Score: ${bonusScore}`
        );

        finalWord.push({
          letter: letter.toUpperCase(),
          score: letterScore,
          type,
          ...(type === 'diamond' && { bonus }),
        });
      });

    const finalScore =
      (goldCount || 1) *
        wordScore *
        (finalWord.at(-1).type === 'dotted' ? 2 : 1) +
      bonusScore;

    debug(
      `(Gold Count: ${goldCount} * Word Score: ${wordScore} * Dotted? [${finalWord.at(-1).type === 'dotted' ? 2 : 1}]) + Bonus Score: ${bonusScore} = Final Score: ${finalScore}`
    );

    this.generateCode(finalScore.toString());

    return {
      tiles: finalWord,
      finalScore,
    };
  }

  generateCode(score) {
    QRCode.toDataURL(
      score,
      {
        errorCorrectionLevel: 'H',
        type: 'image/webp',
      },
      (err, url) => {
        if (err) {
          debug(`Error generating QR code: ${err}`);
          return '';
        }

        this.qrList = [...this.qrList, url];
      }
    );
  }

  getLetterScore(letter) {
    switch (letter) {
      case 'D':
      case 'G':
        return 2;
      case 'B':
      case 'C':
      case 'M':
      case 'P':
        return 3;
      case 'F':
      case 'H':
      case 'V':
      case 'W':
      case 'Y':
        return 4;
      case 'K':
        return 5;
      case 'J':
      case 'X':
        return 8;
      case 'Q':
      case 'Z':
        return 10;
      default:
        return 1; // For any other characters
    }
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

  // randomNumber() {
  //   // Generates a random multiple of 5 from 0 up to 95 (inclusive)
  //   const max = 100 / 5; // 20
  //   return Math.floor(Math.random() * max) * 5;
  // }

  <template>
    {{pageTitle "Mathplay"}}

    {{outlet}}

    <input
      type="text"
      id="word"
      placeholder="Add Word..."
      {{on "keydown" this.submitWord}}
    />

    <p>Add up tiles for
      <strong>Word Score</strong>. Emerald tiles multiply their
      <strong>letter score</strong>
      by 4. Diamond tiles add their bonus to the
      <strong>letter score</strong>. Multiply
      <strong>Word Score</strong>
      by the amount of Gold tiles. Multiply
      <strong>Word Score</strong>
      by 2
      <em>IF</em>
      used in last letter. Bonuses (orange) are added separately.
      <br /><br />
      <strong>Final score</strong>: Gold Count * Word Score (* 2 if last letter
      dotted) + Bonus Score
    </p>

    <ol>
      {{#each this.wordList as |word i|}}
        <li data-final-score={{word.finalScore}}>
          {{#each word.tiles as |tile|}}
            <span
              class="tile"
              data-type={{tile.type}}
              data-bonus={{tile.bonus}}
            >
              <span
                class="score"
                data-letter={{tile.letter}}
                data-score={{tile.score}}
              ></span>
              {{tile.letter}}
            </span>
          {{/each}}

          <img
            class="qr"
            src={{get this.qrList i}}
            alt="Score is {{word.finalScore}}"
          />
        </li>
      {{/each}}
    </ol>
  </template>
}
