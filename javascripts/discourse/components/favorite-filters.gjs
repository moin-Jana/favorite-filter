import Component from "@glimmer/component";
import { action } from "@ember/object";
import didInsert from "@ember/render-modifiers/modifiers/did-insert";
import { service } from "@ember/service";
import FFButtons from "../components/ff-buttons";
import FFLinks from "../components/ff-links";

export default class FavoriteFilters extends Component {
  @service favoriteManager;
  @service router;

  get onFilterRoute() {
    return this.router.currentRouteName === "discovery.filter";
  }

  get currentQuery() {
    return this.router.currentRoute?.queryParams?.q || "";
  }

  @action
  loadOnEnter() {
    this.favoriteManager.loadFavorites();
  }

  <template>
    {{#if this.onFilterRoute}}
      <div class="favorite-filters" {{didInsert this.loadOnEnter}}>
        <FFLinks @currentQuery={{this.currentQuery}} />
        <FFButtons @currentQuery={{this.currentQuery}} />
      </div>
    {{/if}}
  </template>
}
