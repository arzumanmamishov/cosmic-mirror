package handler

import (
	"net/http"

	"cosmic-mirror/internal/domain"
	"cosmic-mirror/internal/middleware"
	"cosmic-mirror/internal/service"

	"github.com/go-chi/chi/v5"
	"github.com/google/uuid"
)

type CommentsHandler struct {
	commentSvc *service.CommentService
	likeSvc    *service.LikeService
}

func NewCommentsHandler(commentSvc *service.CommentService, likeSvc *service.LikeService) *CommentsHandler {
	return &CommentsHandler{commentSvc: commentSvc, likeSvc: likeSvc}
}

func (h *CommentsHandler) ListByPost(w http.ResponseWriter, r *http.Request) {
	userID := middleware.UserIDFromContext(r.Context())
	postID, err := uuid.Parse(chi.URLParam(r, "postID"))
	if err != nil {
		respondError(w, http.StatusBadRequest, "invalid_id", "Invalid post ID")
		return
	}
	comments, err := h.commentSvc.ListByPost(r.Context(), postID, userID)
	if err != nil {
		respondError(w, http.StatusInternalServerError, "comments_list_error", err.Error())
		return
	}
	respondSuccess(w, map[string]any{"comments": comments})
}

func (h *CommentsHandler) Create(w http.ResponseWriter, r *http.Request) {
	userID := middleware.UserIDFromContext(r.Context())
	postID, err := uuid.Parse(chi.URLParam(r, "postID"))
	if err != nil {
		respondError(w, http.StatusBadRequest, "invalid_id", "Invalid post ID")
		return
	}
	var input domain.CreateCommentInput
	if err := decodeBody(r, &input); err != nil {
		respondError(w, http.StatusBadRequest, "invalid_body", "Invalid request body")
		return
	}
	comment, err := h.commentSvc.Create(r.Context(), userID, postID, input)
	if err != nil {
		respondCommunityError(w, err)
		return
	}
	respondCreated(w, comment)
}

func (h *CommentsHandler) Update(w http.ResponseWriter, r *http.Request) {
	userID := middleware.UserIDFromContext(r.Context())
	id, err := uuid.Parse(chi.URLParam(r, "commentID"))
	if err != nil {
		respondError(w, http.StatusBadRequest, "invalid_id", "Invalid comment ID")
		return
	}
	var input domain.UpdateCommentInput
	if err := decodeBody(r, &input); err != nil {
		respondError(w, http.StatusBadRequest, "invalid_body", "Invalid request body")
		return
	}
	if err := h.commentSvc.Update(r.Context(), id, userID, input); err != nil {
		respondCommunityError(w, err)
		return
	}
	respondNoContent(w)
}

func (h *CommentsHandler) Delete(w http.ResponseWriter, r *http.Request) {
	userID := middleware.UserIDFromContext(r.Context())
	id, err := uuid.Parse(chi.URLParam(r, "commentID"))
	if err != nil {
		respondError(w, http.StatusBadRequest, "invalid_id", "Invalid comment ID")
		return
	}
	if err := h.commentSvc.Delete(r.Context(), id, userID); err != nil {
		respondCommunityError(w, err)
		return
	}
	respondNoContent(w)
}

func (h *CommentsHandler) Like(w http.ResponseWriter, r *http.Request) {
	userID := middleware.UserIDFromContext(r.Context())
	id, err := uuid.Parse(chi.URLParam(r, "commentID"))
	if err != nil {
		respondError(w, http.StatusBadRequest, "invalid_id", "Invalid comment ID")
		return
	}
	if err := h.likeSvc.Like(r.Context(), userID, "comment", id); err != nil {
		respondCommunityError(w, err)
		return
	}
	respondNoContent(w)
}

func (h *CommentsHandler) Unlike(w http.ResponseWriter, r *http.Request) {
	userID := middleware.UserIDFromContext(r.Context())
	id, err := uuid.Parse(chi.URLParam(r, "commentID"))
	if err != nil {
		respondError(w, http.StatusBadRequest, "invalid_id", "Invalid comment ID")
		return
	}
	if err := h.likeSvc.Unlike(r.Context(), userID, "comment", id); err != nil {
		respondCommunityError(w, err)
		return
	}
	respondNoContent(w)
}
