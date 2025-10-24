import { apiInitializer } from "discourse/lib/api";
import FavoriteFilters from "../components/favorite-filters";

export default apiInitializer((api) => {
  api.renderInOutlet("discovery-navigation-bar-above", FavoriteFilters);

  const site = api.container.lookup("service:site");
  const userFields = site.user_fields || [];
  const currentUser = api.getCurrentUser();

  const targetFieldId = Number(settings.custom_user_field_ID);
  const field = userFields.find((f) => f.id === targetFieldId);

  if (!field) {
    return;
  }

  if (settings.show_for_admin && currentUser?.admin) {
    return;
  }

  const slug = field.name
    .toLowerCase()
    .replace(/\s+/g, "-")
    .replace(/[^\w-]/g, "");

  api.onPageChange(() => {
    if (typeof document === "undefined") {
      return;
    }

    const el = document.querySelector(`.user-field-${slug}`);
    if (el) {
      el.setAttribute("aria-hidden", "true");
      el.hidden = true;
      el.style.display = "none";
    }
  });
});
