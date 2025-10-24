import Component from "@glimmer/component";
import { tracked } from "@glimmer/tracking";
import { Input } from "@ember/component";
import { fn, hash } from "@ember/helper";
import { on } from "@ember/modifier";
import { action } from "@ember/object";
import { next } from "@ember/runloop";
import { service } from "@ember/service";
import { eq } from "truth-helpers";
import DButton from "discourse/components/d-button";
import DModal from "discourse/components/d-modal";
import EmojiPicker from "discourse/components/emoji-picker";
import RadioButton from "discourse/components/radio-button";
import icon from "discourse/helpers/d-icon";
import { i18n } from "discourse-i18n";
import IconPicker from "select-kit/components/icon-picker";

export default class FFAddLinkModal extends Component {
  @service favoriteManager;
  @service dialog;

  @tracked title = "";
  @tracked query = this.args.model.currentQuery;
  @tracked icon = null;
  @tracked emoji = null;
  @tracked styleType = "none";

  @tracked validationErrorTitle = null;
  @tracked validationErrorQuery = null;

  @action
  updateField(field, event) {
    const value = event?.target?.value ?? event;
    this[field] = value;

    if (field === "title" && this.validationErrorTitle && value?.trim()) {
      this.validationErrorTitle = null;
    }
    if (field === "query" && this.validationErrorQuery && value?.trim()) {
      this.validationErrorQuery = null;
    }
  }

  @action
  async save() {
    let hasError = false;

    if (!this.title?.trim()) {
      this.validationErrorTitle = "modal.error.title_required";
      hasError = true;
    } else {
      this.validationErrorTitle = null;
    }

    if (!this.query?.trim()) {
      this.validationErrorQuery = "modal.error.query_required";
      hasError = true;
    } else {
      this.validationErrorQuery = null;
    }

    if (hasError) {
      return;
    }

    const newFav = {
      label: this.title.trim(),
      query: this.query.trim(),
      icon: this.styleType === "icon" ? this.icon : null,
      emoji: this.styleType === "emoji" ? this.emoji : null,
    };

    const newList = [...this.favoriteManager.favorites, newFav];
    const result = await this.favoriteManager.persistFavorites(newList);

    if (result.success) {
      this.args.closeModal?.();
    } else if (result.reason === "too_long") {
      this.dialog.alert({
        title: i18n(themePrefix("modal.error.too_long_title")),
        message: i18n(themePrefix("modal.error.too_long_message")),
      });
    } else {
      this.dialog.alert({
        message: i18n(themePrefix("modal.error.general_message")),
      });
    }
  }

  @action
  setIconSafely(value) {
    next(() => (this.icon = value));
  }

  @action
  emojiSelected(emoji) {
    next(() => (this.emoji = emoji));
  }

  <template>
    <DModal
      @title={{i18n (themePrefix "modal.title.add_fav")}}
      @closeModal={{@closeModal}}
      class="ff-modal add-link-modal"
    >
      <:body>
        <form class="form-horizontal">
          <div class="form-group">
            <div class="label-row">
              <label>{{i18n (themePrefix "modal.title_label")}}</label>
              {{#if this.validationErrorTitle}}
                <div class="input-error">
                  {{icon "xmark"}}
                  {{i18n (themePrefix this.validationErrorTitle)}}
                </div>
              {{/if}}
            </div>
            <Input
              @value={{this.title}}
              {{on "input" (fn this.updateField "title")}}
              class="form-control"
              aria-invalid={{if this.validationErrorTitle "true" "false"}}
            />
          </div>

          <div class="form-group">
            <div class="label-row">
              <label>{{i18n (themePrefix "modal.query_label")}}</label>
              {{#if this.validationErrorQuery}}
                <div class="input-error">
                  {{icon "xmark"}}
                  {{i18n (themePrefix this.validationErrorQuery)}}
                </div>
              {{/if}}
            </div>
            <Input
              @value={{this.query}}
              {{on "input" (fn this.updateField "query")}}
              class="form-control"
              aria-invalid={{if this.validationErrorQuery "true" "false"}}
            />
          </div>

          <div class="form-group symbol-type-group">
            <label>{{i18n (themePrefix "modal.symbol_type_label")}}</label>

            <div class="symbol-type-layout">
              <div class="symbol-type-options">
                <label class="radio-option">
                  <RadioButton
                    @value="icon"
                    @selection={{this.styleType}}
                    {{on "change" (fn (mut this.styleType) "icon")}}
                  />
                  {{i18n (themePrefix "modal.symbolType.icon")}}
                </label>

                <label class="radio-option">
                  <RadioButton
                    @value="emoji"
                    @selection={{this.styleType}}
                    {{on "change" (fn (mut this.styleType) "emoji")}}
                  />
                  {{i18n (themePrefix "modal.symbolType.emoji")}}
                </label>

                <label class="radio-option">
                  <RadioButton
                    @value="none"
                    @selection={{this.styleType}}
                    {{on "change" (fn (mut this.styleType) "none")}}
                  />
                  {{i18n (themePrefix "modal.symbolType.none")}}
                </label>
              </div>

              <div class="symbol-type-picker">
                {{#if (eq this.styleType "icon")}}
                  <IconPicker
                    @value={{this.icon}}
                    @onChange={{this.setIconSafely}}
                    @onlyAvailable={{true}}
                    @options={{hash maximum=1 icons=this.icon}}
                    aria-label={{i18n (themePrefix "modal.choose_icon_label")}}
                  />
                {{else if (eq this.styleType "emoji")}}
                  <EmojiPicker
                    @emoji={{this.emoji}}
                    @modalForMobile={{false}}
                    @didSelectEmoji={{this.emojiSelected}}
                    @btnClass="btn-emoji"
                    @context="favorite-filter"
                    aria-label={{i18n (themePrefix "modal.choose_emoji_label")}}
                  />
                {{/if}}
              </div>
            </div>
          </div>
        </form>
      </:body>

      <:footer>
        <DButton
          @icon="floppy-disk"
          @translatedLabel={{i18n (themePrefix "modal.save_btn")}}
          @action={{this.save}}
          class="btn-primary"
        />
        <DButton
          @translatedLabel={{i18n (themePrefix "modal.cancel_btn")}}
          @action={{@closeModal}}
          class="btn-flat"
        />
      </:footer>
    </DModal>
  </template>
}
