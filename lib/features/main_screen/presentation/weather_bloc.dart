import 'package:bloc/bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:weather_nearby/core/mapper/data_mapper.dart';
import 'package:weather_nearby/features/data/models/requesting_location.dart';
import 'package:weather_nearby/features/main_screen/data/models/request/weather_request_param.dart';
import 'package:weather_nearby/features/main_screen/data/models/response/whether/weather_data.dart';
import 'package:weather_nearby/features/main_screen/data/weather_repository.dart';

part 'weather_bloc.freezed.dart';

part 'weather_event.dart';

part 'weather_state.dart';

class WeatherBloc extends Bloc<WeatherEvent, WeatherState> {
  final WeatherRepository _weatherRepository;
  final DataMapper<WeatherRequestParam, RequestingLocation> _weatherRequestParamMapper;

  WeatherBloc({
    required WeatherRepository weatherRepository,
    required DataMapper<WeatherRequestParam, RequestingLocation> weatherRequestParamMapper,
  })  : _weatherRepository = weatherRepository,
        _weatherRequestParamMapper = weatherRequestParamMapper,
        super(const WeatherState()) {
    on<WeatherEvent>(
      (event, emit) => event.when<Future<void>>(
        loadData: (location) => _loadData(location, emit),
        updateCurrentWeather: () => _updateCurrentWeather(emit),
      ),
    );
  }

  Future<void> _loadData(RequestingLocation? location, Emitter<WeatherState> emit) async {
    final requestingLocation = location ??
        state.requestingLocation ??
        RequestingLocation(
          location: 'Минск',
        );
    emit(state.copyWith(isLoading: state.requestingLocation != requestingLocation));
    await _updateCurrentWeather(emit);
    final forecastResponse = await _weatherRepository.getForecast(
      _weatherRequestParamMapper.mapToSecond(requestingLocation),
    );
    if (forecastResponse.isSuccess) {
      emit(state.copyWith(forecastWeather: forecastResponse.castedData!));
    }

    emit(state.copyWith(isLoading: false));
  }

  Future<void> _updateCurrentWeather(Emitter<WeatherState> emit) async {
    if (state.requestingLocation == null) {
      return;
    }
    final requestingLocation = state.requestingLocation!;
    final currentWeatherResponse = await _weatherRepository.getCurrentWeather(
      _weatherRequestParamMapper.mapToSecond(requestingLocation),
    );
    emit(state.copyWith(
      currentWeather: currentWeatherResponse.castedData ?? state.currentWeather,
    ));
  }
}