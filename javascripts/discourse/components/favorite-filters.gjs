import Component from "@glimmer/component";
import { tracked } from "@glimmer/tracking";
import { service } from "@ember/service";
import FFButtons from "../components/ff-buttons";
import FFLinks from "../components/ff-links";

export default class FavoriteFilters extends Component {
  @service favoriteManager;
  @service router;

  @tracked isLoaded = false;

  constructor() {
    super(...arguments);
    this.load();
  }

  async load() {
    await this.favoriteManager.loadFavorites();
    this.isLoaded = true;
  }

  get onFilterRoute() {
    return this.router.currentRouteName === "discovery.filter";
  }

  get currentQuery() {
    return this.router.currentRoute.queryParams["q"] || "";
  }

  <template>
    {{#if this.isLoaded}}
      {{#if this.onFilterRoute}}
        <div class="favorite-filters">
          <FFLinks @currentQuery={{this.currentQuery}} />
          <FFButtons @currentQuery={{this.currentQuery}} />
        </div>
      {{/if}}{{/if}}
  </template>
}
