%%
%% Copyright (c) 2019 Dmitry Poroh
%% All rights reserved.
%% Distributed under the terms of the MIT License. See the LICENSE file.
%%
%% SDP media secion tests (m=)
%%

-module(ersip_sdp_media_test).

-include_lib("eunit/include/eunit.hrl").

%%%===================================================================
%%% Cases
%%%===================================================================

-define(crlf, "\r\n").

parse_test() ->
    {ok, Medias} = parse(<<"m=audio 49170/2 RTP/AVP 0" ?crlf>>),
    ?assertEqual(1, length(Medias)),
    [AudioMedia] = Medias,
    ?assertEqual(<<"audio">>,            ersip_sdp_media:type(AudioMedia)),
    ?assertEqual(49170,                  ersip_sdp_media:port(AudioMedia)),
    ?assertEqual(2,                      ersip_sdp_media:port_num(AudioMedia)),
    ?assertEqual([<<"RTP">>, <<"AVP">>], ersip_sdp_media:protocol(AudioMedia)),
    ?assertEqual([<<"0">>],              ersip_sdp_media:formats(AudioMedia)),
    ok.


parse_error_test() ->
    ?assertMatch({error, {invalid_media, _}}, parse(<<"m=@ 49170 RTP/AVP 0" ?crlf>>)),
    ?assertMatch({error, {invalid_media, _}}, parse(<<"m=audio -1 RTP/AVP 0" ?crlf>>)),
    ?assertMatch({error, {invalid_media, _}}, parse(<<"m=audio 49170 @/AVP 0" ?crlf>>)),
    ?assertMatch({error, {invalid_media, _}}, parse(<<"m=audio 49170 RTP/@ 0" ?crlf>>)),
    ?assertMatch({error, {invalid_media, _}}, parse(<<"m=audio 49170 RTP/AVP @" ?crlf>>)),
    ?assertMatch({error, {invalid_media, _}}, parse(<<"m=audio 49170 RTP/AVP" ?crlf>>)),
    ?assertMatch({error, {invalid_media, _}}, parse(<<"m=audio 49170/-1 RTP/AVP 0" ?crlf>>)),
    ok.

set_conn_test() ->
    {ok, Medias} = parse(<<"m=audio 49170/2 RTP/AVP 0" ?crlf>>),
    ?assertEqual(1, length(Medias)),
    [AudioMedia] = Medias,
    ?assertEqual(undefined, ersip_sdp_media:conn(AudioMedia)),
    {ok, Conn, <<>>} = ersip_sdp_conn:parse(<<"c=IN IP4 224.2.17.12/127/2" ?crlf>>),
    AudioMedia1 = ersip_sdp_media:set_conn(Conn, AudioMedia),
    ExpectedSDP = <<"m=audio 49170/2 RTP/AVP 0" ?crlf
                    "c=IN IP4 224.2.17.12/127/2" ?crlf>>,
    ResultSDP = iolist_to_binary(ersip_sdp_media:assemble([AudioMedia1])),
    ?assertEqual(ExpectedSDP, ResultSDP),
    ok.

constructor_test() ->
    Conn = ersip_sdp_conn:new({ip4, {127, 0, 0, 1}}),
    Media1 = ersip_sdp_media:new(<<"audio">>, 49170, [<<"RTP">>, <<"AVP">>], [<<"0">>]),
    assemble_parse([Media1]),
    Media2 = ersip_sdp_media:set_type(<<"video">>, Media1),
    Media3 = ersip_sdp_media:set_port(50000, Media2),
    Media4 = ersip_sdp_media:set_port_num(5, Media3),
    Media5 = ersip_sdp_media:set_protocol([<<"FOO">>, <<"BAR">>, <<"BAZ">>], Media4),
    Media6 = ersip_sdp_media:set_formats([<<"1">>, <<"2">>, <<"3">>], Media5),
    Media7 = ersip_sdp_media:set_conn(Conn, Media6),
    assemble_parse([Media7]).

%%%===================================================================
%%% Helpers
%%%===================================================================

parse(Bin) ->
    case ersip_sdp_media:parse(Bin) of
        {ok, Medias, <<>>} ->
            {ok, Medias};
        {error, _} = Error ->
            Error
    end.

assemble_parse(Medias) ->
    Bin = iolist_to_binary(ersip_sdp_media:assemble(Medias)),
    ?assertEqual({ok, Medias}, parse(Bin)).
