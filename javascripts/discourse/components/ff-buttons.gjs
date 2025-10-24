import Component from "@glimmer/component";
import { action } from "@ember/object";
import { service } from "@ember/service";
import DButton from "discourse/components/d-button";
import { i18n } from "discourse-i18n";
import FFAddLinkModal from "../components/ff-add-link-modal";
import FFEditLinkModal from "../components/ff-edit-link-modal";

export default class FFButtons extends Component {
  @service modal;
  @service favoriteManager;

  get canSaveCurrent() {
    const query = this.args.currentQuery || "";
    return (
      query &&
      !this.favoriteManager.favorites.some(
        (f) => f.query.trim().toLowerCase() === query.trim().toLowerCase()
      )
    );
  }

  @action
  showAddModal() {
    this.modal.show(FFAddLinkModal, {
      model: { currentQuery: this.args.currentQuery },
    });
  }

  @action
  showEditModal() {
    this.modal.show(FFEditLinkModal);
  }

  <template>
    {{#if this.favoriteManager.allowedToCustomizeFilters}}
      <div class="ff-buttons">
        {{#if this.canSaveCurrent}}
          <DButton
            @icon="far-star"
            @action={{this.showAddModal}}
            @translatedTitle={{i18n (themePrefix "filter_buttons.save")}}
            class="btn"
          />
        {{/if}}

        {{#if this.favoriteManager.favorites.length}}
          <DButton
            @icon="pencil"
            @action={{this.showEditModal}}
            @translatedTitle={{i18n (themePrefix "filter_buttons.edit")}}
            class="btn"
          />
        {{/if}}
      </div>
    {{/if}}
  </template>
}
