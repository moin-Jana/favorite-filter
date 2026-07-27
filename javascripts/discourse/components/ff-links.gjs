import Component from "@glimmer/component";
import { concat } from "@ember/helper";
import { service } from "@ember/service";
import { eq } from "discourse/truth-helpers";
import dEmoji from "discourse/ui-kit/helpers/d-emoji";
import dIcon from "discourse/ui-kit/helpers/d-icon";
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
            {{dEmoji fav.emoji}}
          {{else if fav.icon}}
            {{dIcon fav.icon}}
          {{/if}}
          <span class="fav-label">{{fav.label}}</span>
        </a>
      {{/each}}
    </div>
  </template>
}
