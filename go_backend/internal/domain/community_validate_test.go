package domain

import (
	"errors"
	"testing"
)

func TestCommunityInputsRejectBlankText(t *testing.T) {
	blank, ok := "   ", "hello"
	cases := []struct {
		name    string
		err     error
		wantErr bool
	}{
		{"update post blank content", UpdatePostInput{Content: &blank}.Validate(), true},
		{"update post content", UpdatePostInput{Content: &ok}.Validate(), false},
		{"update post link only", UpdatePostInput{}.Validate(), false},
		{"update comment blank content", UpdateCommentInput{Content: &blank}.Validate(), true},
		{"update comment content", UpdateCommentInput{Content: &ok}.Validate(), false},
		{"create space blank name", CreateSpaceInput{Name: blank}.Validate(), true},
		{"create space name", CreateSpaceInput{Name: ok}.Validate(), false},
		{"update space blank name", UpdateSpaceInput{Name: &blank}.Validate(), true},
		{"update space no name", UpdateSpaceInput{}.Validate(), false},
	}
	for _, tc := range cases {
		if (tc.err != nil) != tc.wantErr {
			t.Errorf("%s: err = %v, wantErr %v", tc.name, tc.err, tc.wantErr)
		}
		if tc.err != nil && !errors.Is(tc.err, ErrInvalidInput) {
			t.Errorf("%s: err %v does not wrap ErrInvalidInput", tc.name, tc.err)
		}
	}
}
