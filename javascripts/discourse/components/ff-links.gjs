import Component from "@glimmer/component";
import { concat } from "@ember/helper";
import { service } from "@ember/service";
import { eq } from "truth-helpers";
import icon from "discourse/helpers/d-icon";
import emoji from "discourse/helpers/emoji";
import { i18n } from "discourse-i18n";

export default class FFLinks extends Component {
  @service favoriteManager;

  isActive(favQuery, currentQuery) {
    return (
      favQuery?.trim().toLowerCase() === currentQuery?.trim().toLowerCase()
    );
  }

  <template>
    <div class="ff-links">
      {{#each this.favoriteManager.favorites as |fav|}}
        <a
          href={{concat "/filter?q=" (encodeURIComponent fav.query)}}
          class="btn filter-favorite-btn
            {{if (this.isActive fav.query @currentQuery) 'is-active'}}"
          aria-current={{if (eq fav.query @currentQuery) "page" undefined}}
          aria-label={{i18n (themePrefix "apply_filter") filter=fav.label}}
        >
          {{#if fav.emoji}}
            {{emoji fav.emoji}}
          {{else if fav.icon}}
            {{icon fav.icon}}
          {{/if}}
          <span class="fav-label">{{fav.label}}</span>
        </a>
      {{/each}}
    </div>
  </template>
}
