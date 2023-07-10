package main

import (
	"fmt"
	"net/http"
	"strings"

	spinhttp "github.com/fermyon/spin/sdk/go/http"
	"github.com/fermyon/spin/sdk/go/key_value"
)

const keyPrefix = "fw-"

func init() {
	spinhttp.Handle(func(w http.ResponseWriter, r *http.Request) {
		store, err := key_value.Open("default")
		if err != nil {
			http.Error(w, err.Error(), http.StatusInternalServerError)
			return
		}
		defer key_value.Close(store)

		keys, err := key_value.GetKeys(store)
		if err != nil {
			http.Error(w, err.Error(), http.StatusInternalServerError)
			return
		}

		for _, key := range keys {
			if strings.HasPrefix(key, keyPrefix) {
				if err := key_value.Delete(store, key); err != nil {
					http.Error(w, err.Error(), http.StatusInternalServerError)
					return
				}
			}
		}
		fmt.Fprintln(w, "Finicky Whiskers is reset.")
	})
}

func main() {}
