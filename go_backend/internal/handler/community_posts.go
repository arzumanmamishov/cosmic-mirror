package handler

import (
	"net/http"

	"cosmic-mirror/internal/domain"
	"cosmic-mirror/internal/middleware"
	"cosmic-mirror/internal/service"

	"github.com/go-chi/chi/v5"
	"github.com/google/uuid"
)

type PostsHandler struct {
	postSvc *service.PostService
	likeSvc *service.LikeService
}

func NewPostsHandler(postSvc *service.PostService, likeSvc *service.LikeService) *PostsHandler {
	return &PostsHandler{postSvc: postSvc, likeSvc: likeSvc}
}

func (h *PostsHandler) ListBySpace(w http.ResponseWriter, r *http.Request) {
	userID := middleware.UserIDFromContext(r.Context())
	spaceID, err := uuid.Parse(chi.URLParam(r, "spaceID"))
	if err != nil {
		respondError(w, http.StatusBadRequest, "invalid_id", "Invalid space ID")
		return
	}
	q := r.URL.Query()
	posts, err := h.postSvc.ListBySpace(r.Context(), spaceID, userID,
		parseLimit(q.Get("limit"), 20, 100),
		parseOffset(q.Get("offset")),
	)
	if err != nil {
		respondError(w, http.StatusInternalServerError, "posts_list_error", err.Error())
		return
	}
	respondSuccess(w, map[string]any{"posts": posts})
}

func (h *PostsHandler) Create(w http.ResponseWriter, r *http.Request) {
	userID := middleware.UserIDFromContext(r.Context())
	spaceID, err := uuid.Parse(chi.URLParam(r, "spaceID"))
	if err != nil {
		respondError(w, http.StatusBadRequest, "invalid_id", "Invalid space ID")
		return
	}
	var input domain.CreatePostInput
	if err := decodeBody(r, &input); err != nil {
		respondError(w, http.StatusBadRequest, "invalid_body", "Invalid request body")
		return
	}
	post, err := h.postSvc.Create(r.Context(), userID, spaceID, input)
	if err != nil {
		respondCommunityError(w, err)
		return
	}
	respondCreated(w, post)
}

func (h *PostsHandler) Get(w http.ResponseWriter, r *http.Request) {
	userID := middleware.UserIDFromContext(r.Context())
	id, err := uuid.Parse(chi.URLParam(r, "postID"))
	if err != nil {
		respondError(w, http.StatusBadRequest, "invalid_id", "Invalid post ID")
		return
	}
	post, err := h.postSvc.Get(r.Context(), id, userID)
	if err != nil {
		respondCommunityError(w, err)
		return
	}
	respondSuccess(w, post)
}

func (h *PostsHandler) Update(w http.ResponseWriter, r *http.Request) {
	userID := middleware.UserIDFromContext(r.Context())
	id, err := uuid.Parse(chi.URLParam(r, "postID"))
	if err != nil {
		respondError(w, http.StatusBadRequest, "invalid_id", "Invalid post ID")
		return
	}
	var input domain.UpdatePostInput
	if err := decodeBody(r, &input); err != nil {
		respondError(w, http.StatusBadRequest, "invalid_body", "Invalid request body")
		return
	}
	if err := h.postSvc.Update(r.Context(), id, userID, input); err != nil {
		respondCommunityError(w, err)
		return
	}
	respondNoContent(w)
}

func (h *PostsHandler) Delete(w http.ResponseWriter, r *http.Request) {
	userID := middleware.UserIDFromContext(r.Context())
	id, err := uuid.Parse(chi.URLParam(r, "postID"))
	if err != nil {
		respondError(w, http.StatusBadRequest, "invalid_id", "Invalid post ID")
		return
	}
	if err := h.postSvc.Delete(r.Context(), id, userID); err != nil {
		respondCommunityError(w, err)
		return
	}
	respondNoContent(w)
}

func (h *PostsHandler) Like(w http.ResponseWriter, r *http.Request) {
	userID := middleware.UserIDFromContext(r.Context())
	id, err := uuid.Parse(chi.URLParam(r, "postID"))
	if err != nil {
		respondError(w, http.StatusBadRequest, "invalid_id", "Invalid post ID")
		return
	}
	if err := h.likeSvc.Like(r.Context(), userID, "post", id); err != nil {
		respondCommunityError(w, err)
		return
	}
	respondNoContent(w)
}

func (h *PostsHandler) Unlike(w http.ResponseWriter, r *http.Request) {
	userID := middleware.UserIDFromContext(r.Context())
	id, err := uuid.Parse(chi.URLParam(r, "postID"))
	if err != nil {
		respondError(w, http.StatusBadRequest, "invalid_id", "Invalid post ID")
		return
	}
	if err := h.likeSvc.Unlike(r.Context(), userID, "post", id); err != nil {
		respondCommunityError(w, err)
		return
	}
	respondNoContent(w)
}
