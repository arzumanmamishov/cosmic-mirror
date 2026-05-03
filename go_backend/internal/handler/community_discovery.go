package handler

import (
	"net/http"

	"cosmic-mirror/internal/repository/postgres"
	"cosmic-mirror/internal/service"
)

// DiscoveryHandler exposes the lookup tables that the front end needs to
// render category grids and trending hashtag chips. Read-only.
type DiscoveryHandler struct {
	communitySvc *service.CommunityService
	hashtagRepo  *postgres.HashtagRepository
}

func NewDiscoveryHandler(communitySvc *service.CommunityService, hashtagRepo *postgres.HashtagRepository) *DiscoveryHandler {
	return &DiscoveryHandler{communitySvc: communitySvc, hashtagRepo: hashtagRepo}
}

func (h *DiscoveryHandler) ListCategories(w http.ResponseWriter, r *http.Request) {
	cats, err := h.communitySvc.ListCategories(r.Context())
	if err != nil {
		respondError(w, http.StatusInternalServerError, "categories_error", err.Error())
		return
	}
	respondSuccess(w, map[string]any{"categories": cats})
}

func (h *DiscoveryHandler) ListPopularHashtags(w http.ResponseWriter, r *http.Request) {
	limit := parseLimit(r.URL.Query().Get("limit"), 20, 100)
	tags, err := h.hashtagRepo.ListPopular(r.Context(), limit)
	if err != nil {
		respondError(w, http.StatusInternalServerError, "hashtags_error", err.Error())
		return
	}
	respondSuccess(w, map[string]any{"hashtags": tags})
}
