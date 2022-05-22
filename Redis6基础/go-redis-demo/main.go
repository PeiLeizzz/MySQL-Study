package main

import (
	"context"
	"fmt"
	"log"
	"math/rand"
	"net/http"
	"strconv"

	"github.com/go-redis/redis/v8"
)

func handle(gid, uid string) string {
	if gid == "" || uid == "" {
		return "gid / uid 为空"
	}

	rdb := redis.NewClient(&redis.Options{
		Addr: "127.0.0.1:6379",
		DB:   0,
	})
	if rdb == nil {
		return "redis 连接失败"
	}
	defer rdb.Close()

	kcKey := "sk:" + gid + ":qt"
	userKey := "sk:" + gid + ":user"
	ctx := context.Background()

	ok, err := rdb.SIsMember(ctx, userKey, uid).Result()
	if err != nil {
		return err.Error()
	} else if ok {
		return "用户重复秒杀"
	}

	txf := func(tx *redis.Tx) error {
		kc, err := tx.Get(ctx, kcKey).Result()
		if err != nil {
			return err
		}
		kcInt, err := strconv.Atoi(kc)
		if err != nil {
			return err
		} else if kcInt <= 0 {
			return fmt.Errorf("库存不足，秒杀已结束")
		}

		_, err = tx.TxPipelined(ctx, func(pipe redis.Pipeliner) error {
			pipe.Decr(ctx, kcKey)
			pipe.SAdd(ctx, userKey, uid)
			return nil
		})
		return err
	}

	maxRetries := 200
	for i := 0; i < maxRetries; i++ {
		err = rdb.Watch(ctx, txf, kcKey)
		if err == nil {
			return "秒杀成功"
		} else if err == redis.TxFailedErr {
			continue
		}
		break
	}
	return err.Error()
}

func getUid() string {
	return strconv.Itoa(rand.Intn(9000) + 1000)
}

func shop(w http.ResponseWriter, req *http.Request) {
	values := req.URL.Query()
	gid := values.Get("gid")
	uid := getUid()
	fmt.Println(handle(gid, uid))
}

func main() {
	http.HandleFunc("/", shop)
	log.Fatal(http.ListenAndServe(":8080", nil))
}
